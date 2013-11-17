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

  # Encapsulates the detect, compile, and release functionality for selecting an Mono .NET runtime
  class Mono < NETBuildpack::BaseComponent

    def initialize(context)
      #defaults
      context[:start_script] ||= { :init => [], :run => "" }
      context[:runtime_home] ||= ''
      context[:runtime_command] ||= ''
      context[:config_vars] ||= {}

      super('Mono runtime', context)
      @version, @uri = Mono.find_mono(@configuration)

      #concat seems to be the way to change the param
      context[:runtime_home].concat MONO_HOME
      context[:runtime_command].concat runtime_command
    end

    # Detects which version of Mono this application should use.  
    # Will only return is NOT running on a Windows stack, where the CLR should be used
    #
    # @return [String, nil] returns +mono-<version>+.
    def detect
      return if NETBuildpack::Runtime::Stack.detect_stack == :windows
      id @version
    end

    # Downloads and unpacks Mono
    #
    # @return [void]
    def compile
      download(@version, @uri) { |file| expand file }

      @config_vars["HOME"] = @app_dir
      set_mono_config_vars

      time_operation "Installing Mozilla certificate data to .config/.mono/certs" do
        sh "ln -s #{stage_time_absolute_path("vendor")} /app/vendor", {:silent => true, :env => @config_vars}
        sh "#{stage_time_absolute_path(mozroots_exe)} --import --sync", {:silent => true, :env => @config_vars}
      end
    end

    # Update config_vars and create the start script
    #
    # @return [void]
    def release
      set_mono_config_vars
      start_script_path = create_start_script

      start_script_path
    end

    private

    MONO_HOME = 'vendor/mono'.freeze

    def set_mono_config_vars
      @config_vars["LD_LIBRARY_PATH"] = "$HOME/#{mono_lib}:$LD_LIBRARY_PATH"
      @config_vars["DYLD_LIBRARY_FALLBACK_PATH"] = "$HOME/#{mono_lib}:$DYLD_LIBRARY_FALLBACK_PATH"
      @config_vars["PKG_CONFIG_PATH"] = "$HOME/#{File.join(mono_lib,'pkgconfig')}:$PKG_CONFIG_PATH"
      @config_vars["C_INCLUDE_PATH"] = "$HOME/#{File.join(MONO_HOME,'include')}:$C_INCLUDE_PATH"
      @config_vars["ACLOCAL_PATH"] = "$HOME/#{File.join(MONO_HOME,'share','aclocal')}:$ACLOCAL_PATH"
      @config_vars["PATH"] = "/usr/local/bin:/usr/bin:/bin:$HOME/#{mono_bin}:$PATH"
      @config_vars["RUNTIME_COMMAND"] = "#{runtime_command}"
      @config_vars["XDG_CONFIG_HOME"] = "$HOME/.config"
    end

    def create_start_script
      start_script = "#!/usr/bin/env bash"

      #Add the init command(s)
      @context[:start_script][:init].each do |value|
        start_script = [start_script, "\n", value].join()
      end

      #Add the run command
      start_script = [start_script, "\n", @context[:start_script][:run], "\n"].join()

      start_script_path = File.join(@context[:app_dir], "start.sh")
      File.open(start_script_path, 'w') { |f| f.write(start_script) }

      File.chmod(0555, start_script_path) # -r-xr-xr-x -> Read & Execute

      start_script_path.gsub! @context[:app_dir], "$HOME"
    end

    def expand(file)
      expand_start_time = Time.now
      print "       expanding Mono to #{MONO_HOME} "

      system "rm -rf #{stage_time_absolute_path(MONO_HOME)}"
      system "mkdir -p #{stage_time_absolute_path(MONO_HOME)}"
      system "tar xzf #{file.path} -C #{stage_time_absolute_path(MONO_HOME)} --strip 1 2>&1"

      puts "(#{(Time.now - expand_start_time).duration})"
    end

    def self.find_mono(configuration)
      NETBuildpack::Repository::ConfiguredItem.find_item(configuration)
    rescue => e
      raise RuntimeError, "Error finding mono version: #{e.message}", e.backtrace
    end

    def id(version)
      "mono-#{version}"
    end

    def mono_bin
      File.join MONO_HOME, 'bin'
    end

    def mono_lib
      File.join MONO_HOME, 'lib' 
    end

    def mozroots_exe
      File.join MONO_HOME, 'bin', 'mozroots'
    end
    
    # Returns the command line to execute the runtime
    #
    # @return [String]
    def runtime_command
      "$HOME/#{mono_bin}/mono --server"
    end

  end

end