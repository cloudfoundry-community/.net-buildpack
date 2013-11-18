# Cloud Foundry NET Buildpack
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'net_buildpack/runtime'
require 'net_buildpack/container'
require 'net_buildpack/framework'
require 'net_buildpack/util/constantize'
require 'net_buildpack/util/logger'
require 'net_buildpack/util/run_command'
require 'pathname'
require 'time'
require 'yaml'


module NETBuildpack
  class HookError < RuntimeError; end

	# Encapsulates the detection, compile, and release functionality for NET applications
  class Buildpack

    # Creates a new instance, passing in the application directory.  
    # @param [String] app_dir The application directory
    def initialize(app_dir)
      @logger = NETBuildpack::Util::Logger.new(app_dir)

      Buildpack.dump_environment_variables @logger
      Buildpack.require_component_files
      components = Buildpack.components @logger

      @lib_directory = Buildpack.lib_directory app_dir

      @context = {
          :app_dir => app_dir,
          :lib_directory => @lib_directory,
          :diagnostics => {:directory => NETBuildpack::Util::Logger::DIAGNOSTICS_DIRECTORY},
          :runtime_home => '',
          :runtime_command => '',
          :config_vars => {},
          :start_script => { :init => [], :run_command => "" },
          :logger => @logger
      }

      @runtimes = Buildpack.construct_components(components, 'runtimes', @context, @logger)

      @logger.log @runtimes

      @containers = Buildpack.construct_components(components, 'containers', @context, @logger)

      @logger.log @containers
  
      @frameworks = Buildpack.construct_components(components, 'frameworks', @context, @logger)

      @logger.log @frameworks
    end

    # Iterates over all of the components to detect if this buildpack can be used to run an application
    #
    # @return [Array<String>] An array of strings that identify the components and versions that will be used to run
    #                         this application.  If no container can run the application, the array will be empty
    #                         (+[]+).
    def detect
      run_hook('pre_detect', {:silent => true})

      runtime_detections = Buildpack.component_detections @runtimes

      return [] if runtime_detections.empty?

      container_detections = Buildpack.component_detections(detect_containers)

      return [] if container_detections.empty?

      framework_detections = Buildpack.component_detections @frameworks

      tags = (runtime_detections + container_detections + framework_detections).flatten.compact
      @logger.log "Detection Tags: #{tags}" 

      run_hook('post_detect', {:silent => true})

      tags
    end

    # Transforms the application directory bundling in all dependancies such that application can be run
    #
    # @return [void]
    def compile

      run_hook('pre_compile')

      # Fetch the runtime and container first, 
      # so that any exceptions with too few/many runtimes/containers can be raised
      # before we try do anything else
      the_runtime = runtime
      the_container = container

      FileUtils.mkdir_p @lib_directory

      run_hook('pre_runtime_compile')
      the_runtime.compile
      run_hook('post_runtime_compile')

      the_container.compile

      frameworks.each { |framework| framework.compile }
      
      run_hook('post_compile')
    end

    # Generates the payload required to run the application.  The payload format is defined by the
    # {Heroku Buildpack API}[https://devcenter.heroku.com/articles/buildpack-api#buildpack-api].
    #
    # NB - note that payload config_vars are ignored by CF (use profile.d instead), 
    # and CF only uses the 'web' process type
    #
    # @return [String] The payload required to run the application.
    def release
      run_hook('pre_release', {:silent => true})
      
      frameworks.each { |framework| framework.release }
      container.release
      start_script = runtime.release

      write_profile_d_net_buildpack_env
      
      payload = {
          'addons' => [],
          'config_vars' => {},
          'default_process_types' => {
              'web' => start_script
          }
      }.to_yaml

      @logger.log('Release Payload', payload)

      run_hook('post_release', {:silent => true})

      payload
    end

    private

    COMPONENTS_CONFIG = '../../config/components.yml'.freeze

    LIB_DIRECTORY = '.lib'

    #write env vars to profile.d/net_buildpack_env.sh
    def write_profile_d_net_buildpack_env()
      net_buildpack_env = "#ENV vars required by components configured by the .net-buildpack"
      @context[:config_vars][:BUILDPACK] = ".net-buildpack"
      @context[:config_vars].each do |key, value|
        net_buildpack_env = [net_buildpack_env, "\n", "export #{key}=\"#{value}\""].join()
      end
      profile_d = File.join(@context[:app_dir], ".profile.d")
      net_buildpack_env_sh = File.join(profile_d, "net_buildpack_env.sh")

      FileUtils.mkdir_p(profile_d)
      File.open(net_buildpack_env_sh, 'w') { |f| f.write(net_buildpack_env) }

      @logger.log("#{net_buildpack_env_sh}: ", net_buildpack_env)
    end

    def run_hook(hook_name, options = {})
      options[:silent] ||= false
      exit_value = 0
      if hook_exists?(hook_name) 
        hook_start_time = Time.now
        convert_dos_to_unix_line_endings(hook_path(hook_name))
        cmd = "#{hook_path(hook_name)} #{@context[:app_dir]}"
        print "-----> Running hook: #{cmd} " unless options[:silent]
        exit_value = NETBuildpack::Util::RunCommand.exec(cmd, @logger, {:silent => options[:silent]})
        raise HookError, "Error #{exit_value} running hook: #{cmd}" if exit_value != 0
        puts "-> exitcode:#{exit_value} (#{(Time.now - hook_start_time).duration})" unless options[:silent]
      end
      exit_value
    end 

    def hook_exists?(hook_name)
      return File.exists?(hook_path(hook_name))
    end 

    def hook_path(hook_name)
      return File.join(@context[:app_dir], ".buildpack", "hooks", hook_name)
    end

    def convert_dos_to_unix_line_endings(filename)
      cmd = %{ tr "\\r\\n" "\\n" < #{filename} > #{filename}.unix && cp #{filename}.unix #{filename} && rm #{filename}.unix }
      @logger.log cmd
      @logger.log `#{cmd}`
      @logger.log `cat #{filename}`
    end

    def self.dump_environment_variables(logger)
      logger.log('Environment Variables', ENV.to_hash)
    end

    def self.component_detections(components)
      components.map { |component| component.detect }.compact
    end

    def self.configuration(app_dir, type, logger)
      name = type.match(/^(?:.*::)?(.*)$/)[1].downcase
      config_file = File.expand_path("../../config/#{name}.yml", File.dirname(__FILE__))

      if File.exists? config_file
        configuration = YAML.load_file(config_file)

        logger.log(config_file, configuration)
      end

      configuration || {}
    end

    def self.configure_context(basic_context, type, logger)
      configured_context = basic_context.clone
      configured_context[:configuration] = Buildpack.configuration(configured_context[:app_dir], type, logger)
      configured_context
    end

    def self.construct_components(components, component, basic_context, logger)
      components[component].map do |component|
        component.constantize.new(Buildpack.configure_context(basic_context, component, logger))
      end
    end

    def self.components(logger)
      expanded_path = File.expand_path(COMPONENTS_CONFIG, File.dirname(__FILE__))
      components = YAML.load_file(expanded_path)

      logger.log(expanded_path, components)

      components
    end
    
    def self.runtime_directory
      Pathname.new(File.expand_path('runtime', File.dirname(__FILE__)))
    end

    def self.container_directory
      Pathname.new(File.expand_path('container', File.dirname(__FILE__)))
    end

    def self.framework_directory
      Pathname.new(File.expand_path('framework', File.dirname(__FILE__)))
    end

    def self.lib_directory(app_dir)
      lib_directory = File.join app_dir, LIB_DIRECTORY
    end

    def self.require_component_files
      component_files = runtime_directory.children()
      component_files.concat container_directory.children
      component_files.concat framework_directory.children
      
      component_files.each do |file|
        require file.relative_path_from(root_directory) unless file.directory?
      end
    end

    def self.root_directory
      Pathname.new(File.expand_path('..', File.dirname(__FILE__)))
    end

    def runtime
      runtime_detections = @runtimes.select { |runtime| runtime.detect }
      raise "More than one runtime can run the application: #{runtime_detections.join(', ')}" if runtime_detections.size > 1
      runtime_detections[0]
    end
    
    def detect_containers
      container_detections = @containers.select { |container| container.detect }

      #Procfile container overrides all other container detections
      container_detections = select_container_if_exists(NETBuildpack::Container::Procfile, container_detections)
          
      container_detections
    end

    #reduce container_array to named container if exists, otherwise return passed in containers 
    def select_container_if_exists(container_class, all_containers)
      pruned_containers = all_containers.select { |container| container.class == container_class }
      pruned_containers.size > 0 ? pruned_containers : all_containers
    end

    def container
      detected_containers = detect_containers
      raise "No container can run the application:" if detected_containers.size == 0
      raise "More than one container can run the application: #{detected_containers.join(', ')}" if detected_containers.size > 1

      detected_containers[0]
    end

    def frameworks
      @frameworks.select { |framework| framework.detect }
    end

  end
end