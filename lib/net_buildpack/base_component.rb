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

require 'net_buildpack'
require 'net_buildpack/util/run_command'
require 'net_buildpack/util/application_cache'
require 'net_buildpack/util/logger'

module NETBuildpack

  # A convenience base class for all components in the buildpack.  This base class ensures that the contents of the
  # +context+ are assigned to instance variables matching their keys.  It also ensures that all contract methods are
  # implemented.
  class BaseComponent

    # Creates an instance.  The contents of +context+ are assigned to instance variables matching their keys.
    # +component_name+ and +context+ are exposed via +@component_name+ and +@context+ respectively for any component
    # that wishes to use them.
    #
    # @param [Hash] context A shared context provided to all components
    def initialize(component_name, context)
      @component_name = component_name
      @context = context
      @context.each { |key, value| instance_variable_set("@#{key}", value) }
      @logger ||= NETBuildpack::Util::NullLogger.new
    end

    # If the component should be used when staging an application
    #
    # @return [Array<String>, String, nil] If the component should be used when staging the application, a +String+ or
    #                                      an +Array<String>+ that uniquely identifies the component (e.g.
    #                                      +mono-3.2.3+).  Otherwise, +nil+.
    def detect
      fail "Method 'detect' must be defined"
    end

    # Modifies the application's file system.  The component is expected to transform the application's file system in
    # whatever way is necessary (e.g. downloading files or creating symbolic links) to support the function of the
    # component.  Status output written to +STDOUT+ is expected as part of this invocation.
    #
    # @return [void]
    def compile
      fail "Method 'compile' must be defined"
    end

    # Modifies the application's runtime configuration. The component is expected to transform members of the +context+
    # (e.g. +@java_home+, +@java_opts+, etc.) in whatever way is necessary to support the function of the component.
    #
    # Container components are also expected to create the command required to run the application.  These components
    # are expected to read the +context+ values and take them into account when creating the command.
    #
    # @return [void, String] components other than containers are not expected to return any value.  Container
    #                        compoonents are expected to return the command required to run the application.
    def release
      fail "Method 'release' must be defined"
    end

    protected

    # Times an operation
    #
    # @return [void]
    def time_operation(&block)
      start_time = Time.now
      yield 
      puts "(#{(Time.now - start_time).duration})"
    end

    # Downloads an item with the given name and version from the given URI, then yields the resultant file to the given
    # block.
    #
    # @param [JavaBuildpack::Util::TokenizedVersion] version
    # @param [String] uri
    # @param [String] description an optional description for the download.  Defaults to +@component_name+.
    # @return [void]
    def download(version, uri, description = @component_name, &block)
      download_start_time = Time.now
      print "-----> Downloading #{description} #{version} from #{uri} "

      NETBuildpack::Util::ApplicationCache.new.get(uri) do |file| # TODO: Use global cache #50175265
        puts "(#{(Time.now - download_start_time).duration})"
        yield file
      end
    end

    # Run external shell commands, both streaming and logging output
    #
    # @param [String] cmd the shell script to run
    # @param [Hash] options { :silent => true/false }
    def sh(cmd, options)
      NETBuildpack::Util::RunCommand.exec(cmd, @logger, options)
    end

    # Replace strings in a file.  Modified the original file
    #
    # @param [String] filepath
    # @param [String] old_value 
    # @param [String] new_value 
    def replace_in_file(filepath, old_value, new_value)
      IO.write(filepath, File.open(filepath) do |f|
                            f.read.gsub(/#{old_value}/, new_value)
                          end 
      )
    end


  end

end