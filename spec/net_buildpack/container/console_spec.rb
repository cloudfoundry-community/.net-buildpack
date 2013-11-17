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

        start_script = { :init => [], :run_command => "" }

        Console.new(
          app_dir: 'spec/fixtures/integration_valid',
          configuration: { :arguments => '' },
          runtime_command: '/path/to/mono',
          :start_script => start_script,
        ).release

        expect(start_script[:run_command]).to_not include('vendor/mono')
        expect(start_script[:run_command]).to eq('/path/to/mono z-Start.exe')
      end
    end

  end

end