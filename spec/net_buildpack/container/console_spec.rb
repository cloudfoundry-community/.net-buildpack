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

require 'spec_helper'
require 'fileutils'
require 'net_buildpack/container/console'

module NETBuildpack::Container

  describe Console do

    it 'should detect when .exe.config exists' do
      detected = Console.new(
        app_dir: 'spec/fixtures/integration_valid'
      ).detect

      expect(detected).to eq('console')
    end

    it 'should release correct run_command' do
      Dir.mktmpdir do |root|
        lib_directory = File.join(root, '.lib')
        Dir.mkdir lib_directory

        run_command = Console.new(
          app_dir: 'spec/fixtures/integration_valid',
          configuration: { :arguments => '' },
          runtime_command: 'vendor/mono/bin'
        ).release

        expect(run_command).to eq('vendor/mono/bin bin/Start.exe')
      end
    end

    # it 'should return additional classpath entries when Class-Path is specified' do
    #   Dir.mktmpdir do |root|
    #     lib_directory = File.join(root, '.lib')
    #     Dir.mkdir lib_directory

    #     command = Main.new(
    #       app_dir: 'spec/fixtures/container_main',
    #       java_home: 'test-java-home',
    #       java_opts: [],
    #       lib_directory: lib_directory,
    #       configuration: {}
    #     ).release

    #     expect(command).to eq('test-java-home/bin/java -cp .:alpha.jar:bravo.jar:charlie.jar test-main-class')
    #   end
    # end

    # it 'should return command line arguments when they are specified' do
    #   Dir.mktmpdir do |root|
    #     lib_directory = File.join(root, '.lib')
    #     Dir.mkdir lib_directory

    #     command = Main.new(
    #       app_dir: root,
    #       java_home: 'test-java-home',
    #       java_opts: [],
    #       lib_directory: lib_directory,
    #       configuration: {
    #         'java_main_class' => 'test-java-main-class',
    #         'arguments' => 'some arguments'
    #       }
    #     ).release

    #     expect(command).to eq('test-java-home/bin/java -cp . test-java-main-class some arguments')
    #   end
    # end

    # it 'should return additional libs when they are specified' do
    #   Dir.mktmpdir do |root|
    #     lib_directory = File.join(root, '.lib')
    #     Dir.mkdir lib_directory

    #     Dir['spec/fixtures/additional_libs/*'].each { |file| system "cp #{file} #{lib_directory}" }

    #     command = Main.new(
    #       app_dir: root,
    #       java_home: 'test-java-home',
    #       java_opts: [],
    #       lib_directory: lib_directory,
    #       configuration: { 'java_main_class' => 'test-java-main-class' }
    #     ).release

    #     expect(command).to eq('test-java-home/bin/java -cp .:.lib/test-jar-1.jar:.lib/test-jar-2.jar test-java-main-class')
    #   end

    # end

  end

end