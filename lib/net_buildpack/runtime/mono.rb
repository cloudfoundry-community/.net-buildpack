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

  # Encapsulates the detect, compile, and release functionality for selecting an Mono .NET runtime
  class Mono

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
      download_start_time = Time.now
      print "-----> Downloading Mono #{@version} from #{@uri} "

      NETBuildpack::Util::ApplicationCache.new.get(@uri) do |file|  # TODO Use global cache #50175265
        puts "(#{(Time.now - download_start_time).duration})"
        expand file
      end

      print "-----> Downloading Mozilla certificate data "
      NETBuildpack::Util::ApplicationCache.new.get(MOZILLA_CERTS_URL) do |file|  
        puts "(#{(Time.now - download_start_time).duration})"
        add_cert_installation_to_startup file
      end

      system "echo 'ln -s #{runtime_time_absolute_path("vendor")} /app/vendor' >> #{stage_time_absolute_path(setup_mono)}"
    end

    # Update config_vars
    #
    # @return [void]
    def release

      @config_vars["LD_LIBRARY_PATH"] = "#{runtime_time_absolute_path(mono_lib)}:$LD_LIBRARY_PATH"
      @config_vars["DYLD_LIBRARY_FALLBACK_PATH"] = "#{runtime_time_absolute_path(mono_lib)}:$DYLD_LIBRARY_FALLBACK_PATH"
      @config_vars["PKG_CONFIG_PATH"] = "#{runtime_time_absolute_path(File.join(mono_lib,'pkgconfig'))}:$PKG_CONFIG_PATH"
      @config_vars["C_INCLUDE_PATH"] = "#{runtime_time_absolute_path(File.join(MONO_HOME,'include'))}:$C_INCLUDE_PATH"
      @config_vars["ACLOCAL_PATH"] = "#{runtime_time_absolute_path(File.join(MONO_HOME,'share','aclocal'))}:$ACLOCAL_PATH"
      @config_vars["PATH"] = "#{runtime_time_absolute_path(mono_bin)}:$PATH"

    end

    private

    MONO_HOME = 'vendor/mono'.freeze
    MOZILLA_CERTS_URL = "http://mxr.mozilla.org/seamonkey/source/security/nss/lib/ckfw/builtins/certdata.txt?raw=1"

    def expand(file)
      expand_start_time = Time.now
      print "       expanding Mono to #{MONO_HOME} "

      system "rm -rf #{stage_time_absolute_path(MONO_HOME)}"
      system "mkdir -p #{stage_time_absolute_path(MONO_HOME)}"
      system "tar xzf #{file.path} -C #{stage_time_absolute_path(MONO_HOME)} --strip 1 2>&1"

      puts "(#{(Time.now - expand_start_time).duration})"
    end

    def add_cert_installation_to_startup(file)
      FileUtils.move file, File.join( @app_dir, mozilla_certs_file )
      system "echo '#{mozroots_exe} --import --sync --file #{mozilla_certs_file}' >> #{stage_time_absolute_path(setup_mono)}"
      system "chmod +x #{stage_time_absolute_path(setup_mono)}"
    end

    def self.find_mono(configuration)
      NETBuildpack::Repository::ConfiguredItem.find_item(configuration)
    rescue => e
      raise RuntimeError, "Error finding mono version: #{e.message}", e.backtrace
    end

    def id(version)
      "mono-#{version}"
    end

    def stage_time_absolute_path(path)
      File.join @app_dir, path
    end

    def runtime_time_absolute_path(path)
      File.join "/app", path
    end

    def mono_bin
      File.join MONO_HOME, 'bin', 'mono'
    end

    def mono_lib
      File.join MONO_HOME, 'lib' 
    end

    def setup_mono
      File.join MONO_HOME, 'bin', 'setup_mono'
    end 

    def mozilla_certs_file
      File.join MONO_HOME, "mozilla_certsdata.txt"
    end

    def mozroots_exe
      File.join MONO_HOME, 'bin', 'mozroots'
    end
    
    # Returns the command line to execute the runtime
    #
    # @return [String]
    def runtime_command
      "#{runtime_time_absolute_path(setup_mono)} && #{runtime_time_absolute_path(mono_bin)}"
    end

  end

end