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
require 'net_buildpack/util/logger'
require 'pathname'
require 'time'
require 'yaml'

module NETBuildpack

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

      basic_context = {
          :app_dir => app_dir,
          :lib_directory => @lib_directory,
          :diagnostics => {:directory => NETBuildpack::Util::Logger::DIAGNOSTICS_DIRECTORY}
      }

       @runtimes = Buildpack.construct_components(components, 'runtimes', basic_context, @logger)

    end

    # Iterates over all of the components to detect if this buildpack can be used to run an application
    #
    # @return [Array<String>] An array of strings that identify the components and versions that will be used to run
    #                         this application.  If no container can run the application, the array will be empty
    #                         (+[]+).
    def detect
      runtime_detections = Buildpack.component_detections @runtimes
      raise "Application can be run using more than one Runtime: #{runtime_detections.join(', ')}" if runtime_detections.size > 1

      ['console']
    end

    # Transforms the application directory bundling in all dependancies such that application can be run
    #
    # @return [void]
    def compile
      FileUtils.mkdir_p @lib_directory

      @logger.log('TODO - compiling')
    end

    # Generates the payload required to run the application.  The payload format is defined by the
    # {Heroku Buildpack API}[https://devcenter.heroku.com/articles/buildpack-api#buildpack-api].
    #
    # @return [String] The payload required to run the application.
    def release

      command = "bin/start.sh"

      payload = {
          'addons' => [],
          'config_vars' => {},
          'default_process_types' => {
              'web' => command
          }
      }.to_yaml

      @logger.log('Release Payload', payload)

      payload
    end

    private

    COMPONENTS_CONFIG = '../../config/components.yml'.freeze

    LIB_DIRECTORY = '.lib'

    def self.dump_environment_variables(logger)
      logger.log('Environment Variables', ENV.to_hash)
    end

    def self.component_detections(components)
      components.map { |component| component.detect }.compact
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

    def self.lib_directory(app_dir)
      lib_directory = File.join app_dir, LIB_DIRECTORY
    end

    def self.require_component_files
      component_files = runtime_directory.children()
      # component_files.concat framework_directory.children
      # component_files.concat container_directory.children

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
  end
end