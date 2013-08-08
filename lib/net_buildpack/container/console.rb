# Encoding: utf-8
# Cloud Foundry NET Buildpack
# Copyright 2013 the original author or authors.
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

require 'net_buildpack/container'
require 'net_buildpack/container/container_utils'

module NETBuildpack::Container

  class ConsoleExeNotFoundError < RuntimeError; end

  # Encapsulates the detect, compile, and release functionality for applications running a simple Console .exe
  # This isn't a _container_ in the traditional sense, but contains the functionality to manage the lifecycle 
  # Console applications.
  class Console

    # Creates an instance, passing in an arbitrary collection of options.
    #
    # @param [Hash] context the context that is provided to the instance
    # @option context [String] :app_dir the directory that the application exists in
    # @option context [String] :mono_home the directory that acts as +MONO_HOME+
    # @option context [String] :lib_directory the directory that additional libraries are placed in
    # @option context [Hash] :configuration the properties provided by the user
    def initialize(context = {})
      @app_dir = context[:app_dir]
      @runtime_command = context[:runtime_command]
      @lib_directory = context[:lib_directory]
      @configuration = context[:configuration]
    end

    # Detects whether this application is Console application application.
    #
    # @return [String] returns +console+ if a .exe is found in the bin folder
    def detect
      console_executable ? CONTAINER_NAME : nil
    end

    # Does nothing as no transformations are required when running Java +main()+ applications.
    #
    # @return [void]
    def compile
    end

    # Creates the command to run the Console application.
    #
    # @return [String] the command to run the application.
    def release
      runtime_command = ContainerUtils.space(@runtime_command)
      exe_string = ContainerUtils.space(console_executable)
      arguments_string = ContainerUtils.space(arguments)

      "#{runtime_command}#{exe_string}#{arguments_string}".strip
    end

    private

      ARGUMENTS_PROPERTY = 'arguments'.freeze
      CONTAINER_NAME = 'console'.freeze

      def arguments
        @configuration[ARGUMENTS_PROPERTY]
      end

      def console_executable
        exe_configs = Dir.glob(File.join( @app_dir, "**", "*.exe.config" ), File::FNM_CASEFOLD) 
        exe_configs = exe_configs.reject{ |f| f[/.*vshost.*/i] } # don't try to run vshost.exe files
        exe_config = exe_configs.first  # returns first .exe found, or nil
        raise(ConsoleExeNotFoundError, "Unable to find any exe.config files in #{@app_dir}") if exe_config.nil?

        exe_config = exe_config.gsub /#{@app_dir}\//, '' # make it relative
        exe = exe_config.gsub /.config/i, '' # reference the associated exe
        exe
      end

  end

end