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

  # Encapsulates the detect, compile, and release functionality for NET applications whose start command is embedded in a Procfile
  # This isn't a _container_ in the traditional sense, but contains the functionality to manage a set of .NET applications working together
  class Procfile 

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

    def detect
      find_file("Procfile") ? id : nil
    end

    def compile 
      Downloading "-----> Downloading Forego 'current.linux-amd64' from #{FOREGO_URI} "
      download "current.linux-amd64", FOREGO_URI, "forego (Foreman in Go)" do |file|
        system "chmod +x #{file.path}"
        system "cp #{file.path} #{@lib_directory}/forego"  
      end
    end

    def release
      foreman_string = "#{relative_lib_directory}/forego start -p $PORT"

      "#{foreman_string}"
    end

    private

    ARGUMENTS_PROPERTY = 'arguments'.freeze
    FOREGO_URI = 'https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego'.freeze

    def arguments
      @configuration[ARGUMENTS_PROPERTY]
    end

    def id
      'net-procfile'
    end

    def find_file(filename)
      filepath = File.join(@app_dir, filename)
      filepath = File.exists?(filepath) ? filepath : nil
      filepath
    end

    def relative_lib_directory
      @lib_directory.sub! "#{@app_dir}/", './'
    end

  end

end