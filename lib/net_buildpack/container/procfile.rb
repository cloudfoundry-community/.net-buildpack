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

require 'net_buildpack/base_component'
require 'net_buildpack/container'
require 'net_buildpack/container/container_utils'

module NETBuildpack::Container

  # Encapsulates the detect, compile, and release functionality for NET applications whose start command is embedded in a Procfile
  # This isn't a _container_ in the traditional sense, but contains the functionality to manage a set of .NET applications working together
  class Procfile < NETBuildpack::BaseComponent

    def initialize(context)
      super('Procfile container', context)
    end

    def detect
      find_file("Procfile") ? id : nil
    end

    def compile 
      download("current.linux-amd64", FOREGO_URI) do |file| 
        sh "chmod +x #{file.path}", {:silent => true}
        sh "mkdir -p #{stage_time_absolute_path('vendor')}", {:silent => true}
        sh "cp #{file.path} #{stage_time_absolute_path('vendor/forego')}", {:silent => true}
      end

      #otherwise CF runtime will use the web: element as the start command 
      #rather than the 'forego start' command we specify
      time_operation "Patching Procfile to rename web: to _web:" do
        replace_in_file(find_file("Procfile"),"web:","_web:")
      end
      
    end

    def release
      @start_script[:run_command] = "#{runtime_time_absolute_path('vendor/forego')} start -p $PORT"
    end

    private

    FOREGO_URI = 'https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego'.freeze

    def id
      'net-procfile'
    end

    def find_file(filename)
      filepath = File.join(@app_dir, filename)
      filepath = File.exists?(filepath) ? filepath : nil
      filepath
    end

  end

end