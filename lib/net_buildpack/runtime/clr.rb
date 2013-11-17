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
require 'net_buildpack/base_component'
require 'net_buildpack/runtime'
require 'net_buildpack/runtime/stack'
require 'net_buildpack/repository/configured_item'
require 'net_buildpack/util/application_cache'
require 'net_buildpack/util/format_duration'
require 'net_buildpack/util/tokenized_version'

module NETBuildpack::Runtime

  # Encapsulates the detect, compile, and release functionality for selecting the Windows .NET CLR
  class CLR < NETBuildpack::BaseComponent

    def initialize(context)
      #defaults
      context[:start_script] ||= { :init => [], :run => "" }

      super('CLR runtime', context)
      @version = CLR.find_clr(@configuration)

      #concat seems to be the way to change the param
      context[:runtime_command].concat runtime_command 
    end

    # Detects which version of .NET CLR this application should use.  *NOTE:* This method will always return _some_ value,
    # so it should only be used once that application has already been established to be a Mono application.
    #
    # @return [String, nil] returns +clr-<version>+.
    def detect
      return unless NETBuildpack::Runtime::Stack.detect_stack == :windows
      id @version
    end

    # Downloads and unpacks Mono
    #
    # @return [void]
    def compile
      
    end

    # Update config_vars and write start script
    #
    # @return [void]
    def release
      start_script_path = create_start_script

      start_script_path
    end

    private

    def create_start_script
      start_script = ""

      #Add the init command(s)
      @context[:start_script][:init].each do |value|
        start_script = [start_script, "\r\n", value].join()
      end

      #Add the run command
      start_script = [start_script, "\r\n", @context[:start_script][:run], "\r\n"].join()

      start_script_path = File.join(@context[:app_dir], "start.cmd")
      File.open(start_script_path, 'w') { |f| f.write(start_script) }

      start_script_path.gsub! @context[:app_dir], "$HOME"
    end

    def self.find_clr(configuration)
      return configuration[:version]
    rescue => e
      raise RuntimeError, "Error finding CLR version: #{e.message}", e.backtrace
    end

    def id(version)
      "clr-#{version}"
    end

    def stage_time_absolute_path(path)
      File.join @app_dir, path
    end

    def runtime_time_absolute_path(path)
      File.join "/app", path
    end

    
    # Returns the command line to execute the runtime
    # On a Windows system this is effectively "" since Windows will open the .exe directly
    #
    # @return [String]
    def runtime_command
      ""
    end

  end

end