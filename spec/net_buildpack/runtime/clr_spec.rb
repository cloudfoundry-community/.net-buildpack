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

    # it 'adds setup_mono to run_command' do
    #   Dir.mktmpdir do |root|
    #     NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)

    #     run_command = ""
    #     CLR.new(
    #         :app_dir => root,
    #         :runtime_home => '',
    #         :runtime_command => run_command,
    #         :config_vars => {},
    #         :diagnostics => {:directory => 'fake-diagnostics-dir'},
    #         :configuration => {}
    #     ).release

    #     expect(run_command).to include("setup_mono")
    #   end
    # end

    # it 'adds correct env vars to config_vars ' do
    #   Dir.mktmpdir do |root|
    #     NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)

    #     config_vars = {}
    #     Mono.new(
    #         :app_dir => root,
    #         :runtime_home => '',
    #         :runtime_command => '',
    #         :config_vars => config_vars,
    #         :diagnostics => {:directory => 'fake-diagnostics-dir'},
    #         :configuration => {}
    #     ).release

    #     expect(config_vars["LD_LIBRARY_PATH"]).to include("/app/vendor/mono/lib")
    #     expect(config_vars["DYLD_LIBRARY_FALLBACK_PATH"]).to include("/app/vendor/mono/lib")
    #     expect(config_vars["C_INCLUDE_PATH"]).to include("/app/vendor/mono/include")
    #     expect(config_vars["ACLOCAL_PATH"]).to include("/app/vendor/mono/share/aclocal")
    #     expect(config_vars["PKG_CONFIG_PATH"]).to include("/app/vendor/mono/lib/pkgconfig")
    #     expect(config_vars["PATH"]).to include("/app/vendor/mono/bin")
    #   end
    # end

  end

end