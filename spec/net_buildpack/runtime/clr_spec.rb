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
require 'net_buildpack/runtime/clr'

module NETBuildpack::Runtime

  describe CLR do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    it 'should detect with id of clr-<version>' do
        NETBuildpack::Runtime::Stack.stub(:detect_stack).and_return(:windows)
        expect(detected).to eq('clr-4.3.2222')
    end

    it 'should detect when running on Windows' do
        NETBuildpack::Runtime::Stack.stub(:detect_stack).and_return(:windows)
        expect(detected).to eq('clr-4.3.2222')
    end

    it 'should NOT detect when NOT running on Windows' do
        NETBuildpack::Runtime::Stack.stub(:detect_stack).and_return(:other)
        expect(detected).to be_nil
    end

    def detected
        result = nil
        Dir.mktmpdir do |root|
            result = CLR.new(
                :app_dir => root,
                :runtime_home => '',
                :runtime_command => '',
                :config_vars => {},
                :diagnostics => {:directory => 'fake-diagnostics-dir'},
                :configuration => { :version => "4.3.2222" }
            ).detect
        end
        result
    end

  end

end