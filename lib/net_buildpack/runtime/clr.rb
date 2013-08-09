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
require 'net_buildpack/runtime/stack'
require 'net_buildpack/repository/configured_item'
require 'net_buildpack/util/application_cache'
require 'net_buildpack/util/format_duration'
require 'net_buildpack/util/tokenized_version'

module NETBuildpack::Runtime

  # Encapsulates the detect, compile, and release functionality for selecting the Windows .NET CLR
  class CLR

    # Creates an instance, passing in an arbitrary collection of options.
    #
    # @param [Hash] context the context that is provided to the instance
    # @option context [String] :app_dir the directory that the application exists in
    # @option context [String] :runtime_command the command to launch the runtime
    # @option context [Hash] :config_vars the config vars used to set the environment
    # @option context [Hash] :configuration the properties provided by the user
    # @option context [Hash] :diagnostics the diagnostics information provided by the buildpack
    def initialize(context)
      @config_vars = context[:config_vars] 
      @app_dir = context[:app_dir]
      @configuration = context[:configuration]
      @diagnostics_directory = context[:diagnostics][:directory] # Note this is a relative directory.
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

    # Update config_vars
    #
    # @return [void]
    def release

    end

    private

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