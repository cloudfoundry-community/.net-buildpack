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
require 'net_buildpack/framework'

module NETBuildpack::Framework

  # Encapsulates the detect, compile, and release functionality for enabling cloud auto-reconfiguration in Spring
  # applications.
  class AppSettingsAutoReconfiguration < NETBuildpack::BaseComponent

    def initialize(context)
      super('AppSettings Auto-reconfiguration', context)
    end

    # Detects whether there is a config file to be modified
    #
    # @return [String, nil] returns +appsettings_auto_reconfiguration+.
    def detect
      config_files.any? ? "app_settings_auto_reconfiguration" : nil
    end

    def compile
      time_operation "Preparing AppSettingsAutoReconfiguration.exe" do
        vendor_dir = File.join(@app_dir, 'vendor')
        FileUtils.mkdir_p vendor_dir

        FileUtils.cp File.join(resources_dir, 'AppSettingsAutoReconfiguration', 'bin', 'AppSettingsAutoReconfiguration.exe'),\
                     File.join(vendor_dir, 'AppSettingsAutoReconfiguration.exe')

        ensure_config_is_lowercase
      end
    end

    def release
      config_files.each do |config_file|
        file = config_file.gsub! @app_dir, "$HOME" #make relative 
        @start_script[:init] << "mono $HOME/vendor/AppSettingsAutoReconfiguration.exe #{file}"
      end  
    end

    private

    def resources_dir
      File.expand_path(File.join('..', '..', '..', 'resources'), File.dirname(__FILE__))
    end

    def config_files
      configs = Dir.glob(File.join( @app_dir, "**", "*.exe.config" ), File::FNM_CASEFOLD) 
      configs = configs.reject{ |f| f[/.*vshost.*/i] } # don't try to run vshost.exe files
      configs = configs.reject{ |f| f[/.*vendor.*/i] } # shouldn't use anything below vendor/
      configs
    end

    #Mono on Linux wants .config, not .Config
    def ensure_config_is_lowercase
      config_files.each do |config_file|
        if /Config$/.match( config_file )
          lowercase_name = config_file.gsub! ".Config", ".config"
          FileUtils.mv config_file, lowercase_name
          puts "      Renaming #{config_file.gsub! @app_dir, ''} to #{lowercase_name.gsub! @app_dir, ''}"
        end
      end
    end
  end

end