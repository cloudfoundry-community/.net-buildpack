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
require 'net_buildpack/container'
require 'net_buildpack/util/constantize'
require 'net_buildpack/util/logger'
require 'pathname'
require 'time'
require 'yaml'
require 'open3'

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
          :config_vars => {}
      }

      @runtimes = Buildpack.construct_components(components, 'runtimes', @context, @logger)

      @containers = Buildpack.construct_components(components, 'containers', @context, @logger)
  
    #  @frameworks = Buildpack.construct_components(components, 'frameworks', basic_context, @logger)

    end

    # Iterates over all of the components to detect if this buildpack can be used to run an application
    #
    # @return [Array<String>] An array of strings that identify the components and versions that will be used to run
    #                         this application.  If no container can run the application, the array will be empty
    #                         (+[]+).
    def detect
      run_hook('pre_detect')

      runtime_detections = Buildpack.component_detections @runtimes
      raise "Application can be run using more than one Runtime: #{runtime_detections.join(', ')}" if runtime_detections.size > 1

      container_detections = Buildpack.component_detections @containers
      raise "Application can be run by more than one container: #{container_detections.join(', ')}" if container_detections.size > 1

     # framework_detections = Buildpack.component_detections @frameworks
      framework_detections = []

      run_hook('post_detect') 

      tags = container_detections.empty? ? [] : runtime_detections.concat(framework_detections).concat(container_detections).flatten.compact
      @logger.log "Detection Tags: #{tags}" 
      tags
    end

    # Transforms the application directory bundling in all dependancies such that application can be run
    #
    # @return [void]
    def compile
      FileUtils.mkdir_p @lib_directory

      run_hook('pre_compile')

      run_hook('pre_runtime_compile')
      runtime.compile
      run_hook('post_runtime_compile')
      container.compile
      #frameworks.each { |framework| framework.compile }
      
      run_hook('post_compile')
    end

    # Generates the payload required to run the application.  The payload format is defined by the
    # {Heroku Buildpack API}[https://devcenter.heroku.com/articles/buildpack-api#buildpack-api].
    #
    # @return [String] The payload required to run the application.
    def release
      run_hook('pre_release')
      runtime.release
      command = container.release
      #frameworks.each { |framework| framework.release }

      payload = {
          'addons' => [],
          'config_vars' => @context[:config_vars],
          'default_process_types' => {
              'web' => command
          }
      }.to_yaml

      @logger.log('Release Payload', payload)

      run_hook('post_release')

      payload
    end

    private

    COMPONENTS_CONFIG = '../../config/components.yml'.freeze

    LIB_DIRECTORY = '.lib'
   
    def run_hook(hook_name)
      exit_value = 0
      if hook_exists?(hook_name) 
        hook_start_time = Time.now
        cmd = "#{hook_path(hook_name)} #{@context[:app_dir]}"
        print "-----> Running hook: #{cmd} "
     
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
           exit_value = wait_thr.value
           output = "#{stdout.read}\n#{stderr.read}"
           @logger.log("#{cmd}, exit code: #{exit_value}, output: }", output)
           raise HookError, "Error #{exit_value} running hook: #{cmd}" if exit_value != 0
        end
        puts "(#{(Time.now - hook_start_time).duration})"
      end
      exit_value
    end 

    def hook_exists?(hook_name)
      return File.exists?(hook_path(hook_name))
    end 

    def hook_path(hook_name)
      return File.join(@context[:app_dir], ".buildpack", "hooks", hook_name)
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

    def self.lib_directory(app_dir)
      lib_directory = File.join app_dir, LIB_DIRECTORY
    end

    def self.require_component_files
      component_files = runtime_directory.children()
      component_files.concat container_directory.children
      # component_files.concat framework_directory.children
      
      component_files.each do |file|
        require file.relative_path_from(root_directory) unless file.directory?
      end
    end

    def self.root_directory
      Pathname.new(File.expand_path('..', File.dirname(__FILE__)))
    end

    def runtime
      @runtimes.detect { |runtime| runtime.detect }
    end
    
    def container
      @containers.find { |container| container.detect }
    end

    # def frameworks
    #   @frameworks.select { |framework| framework.detect }
    # end

  end
end