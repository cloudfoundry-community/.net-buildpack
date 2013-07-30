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

require 'net_buildpack/runtime'
require 'net_buildpack/repository/configured_item'
require 'net_buildpack/util/application_cache'
require 'net_buildpack/util/format_duration'
require 'net_buildpack/util/tokenized_version'

module NETBuildpack::Runtime

  # Encapsulates the detect, compile, and release functionality for selecting an OpenJDK JRE.
  class Mono

    # Creates an instance, passing in an arbitrary collection of options.
    #
    # @param [Hash] context the context that is provided to the instance
    # @option context [String] :app_dir the directory that the application exists in
    # @option context [String] :java_home the directory that acts as +JAVA_HOME+
    # @option context [Array<String>] :java_opts an array that Java options can be added to
    # @option context [Hash] :configuration the properties provided by the user
    # @option context [Hash] :diagnostics the diagnostics information provided by the buildpack
    def initialize(context)
      @app_dir = context[:app_dir]
      @configuration = context[:configuration]
      @diagnostics_directory = context[:diagnostics][:directory] # Note this is a relative directory.
      @version, @uri = Mono.find_mono(@configuration)
      @profile = @configuration[KEY_PROFILE]

      context[:mono_home].concat MONO_HOME
    end

    # Detects which version of Mono this application should use.  *NOTE:* This method will always return _some_ value,
    # so it should only be used once that application has already been established to be a Mono application.
    #
    # @return [String, nil] returns +openjdk-<version>+.
    def detect
      id @version, @profile
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
      copy_resources
    end

    # ??
    #
    # @return [void]
    def release
      
    end

    private

    MONO_HOME = '.mono'.freeze
    
    KEY_PROFILE = 'profile'

    def expand(file)
      expand_start_time = Time.now
      print "       Expanding Mono to #{MONO_HOME} "

      system "rm -rf #{mono_home}"
      system "mkdir -p #{mono_home}"
      system "tar xzf #{file.path} -C #{mono_home} --strip 1 2>&1"

      puts "(#{(Time.now - expand_start_time).duration})"
    end

    def self.find_mono(configuration)
      NETBuildpack::Repository::ConfiguredItem.find_item(configuration)
    rescue => e
      raise RuntimeError, "Error finding mono version: #{e.message}", e.backtrace
    end

    def id(version, profile)
      "mono-#{version}-#{profile}"
    end

    def mono_home
      File.join @app_dir, MONO_HOME
    end

  end

end