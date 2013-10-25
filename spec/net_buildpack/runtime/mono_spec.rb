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
require 'net_buildpack/runtime/mono'

module NETBuildpack::Runtime

  describe Mono do

    DETAILS = [NETBuildpack::Util::TokenizedVersion.new('3.2.0'), 'test-uri']

    let(:application_cache) { double('ApplicationCache') }

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)
      NETBuildpack::Util::ApplicationCache.stub(:new).and_return(application_cache)
      application_cache.stub(:get).with('test-uri').and_yield(File.open('spec/fixtures/stub-mono.tar.gz'))
        
    end

    it 'should detect with id of mono-<version>' do
      Dir.mktmpdir do |root|
        
        NETBuildpack::Runtime::Stack.stub(:detect_stack).and_return(:linux)

        detected = Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).detect

        expect(detected).to eq('mono-3.2.0')
      end
    end

    it 'should not detect when running on Windows' do
      Dir.mktmpdir do |root|
        
        NETBuildpack::Runtime::Stack.stub(:detect_stack).and_return(:windows)
        detected = Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
          ).detect
        expect(detected).to be_nil
      end
    end

    it 'should extract Mono from a GZipped TAR' do
      Dir.mktmpdir do |root|
        
        detected = Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).compile

        mono = File.join(root, 'vendor', 'mono', 'bin', 'mono')
        expect(File.exists?(mono)).to be_true
      end
    end

    it 'should fail when ConfiguredItem.find_item fails' do
      Dir.mktmpdir do |root|
        NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_raise('test error')
        expect do
          Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
          ).detect
        end.to raise_error(/Error\ finding\ mono\ version:\ test\ error/)
      end
    end

    it 'runs mozroots with XDG_CONFIG_HOME set correctly' do
      Dir.mktmpdir do |root|

        NETBuildpack::Util::RunCommand.stub(:exec) do |cmd, logger, options|
            case cmd
            when /ln.+/i
                cmd.should include('-s')
                cmd.should include("#{root}/vendor /app/vendor")
            when /.*mozroots.*/i
                cmd.should include('mozroots')
                cmd.should include('--import')
                cmd.should include('--sync')
                options[:env].should include('HOME'=>root, 'XDG_CONFIG_HOME' => '$HOME/.config')
            end
            0
        end

        detected = Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).compile
      end
    end

    it 'runs mono with the --server flag (see http://www.mono-project.com/Release_Notes_Mono_3.2#New_in_Mono_3.2.3)' do
      Dir.mktmpdir do |root|

        run_command = ""
        Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => run_command,
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).release

        expect(run_command).to include("mono --server")
      end
    end

    it 'adds correct env vars to config_vars ' do
      Dir.mktmpdir do |root|

        config_vars = {}
        Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => config_vars,
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).release

        expect(config_vars["LD_LIBRARY_PATH"]).to include("$HOME/vendor/mono/lib")
        expect(config_vars["DYLD_LIBRARY_FALLBACK_PATH"]).to include("$HOME/vendor/mono/lib")
        expect(config_vars["C_INCLUDE_PATH"]).to include("$HOME/vendor/mono/include")
        expect(config_vars["ACLOCAL_PATH"]).to include("$HOME/vendor/mono/share/aclocal")
        expect(config_vars["PKG_CONFIG_PATH"]).to include("$HOME/vendor/mono/lib/pkgconfig")
        expect(config_vars["PATH"]).to include("/usr/local/bin:/usr/bin:/bin:$HOME/vendor/mono/bin")
        expect(config_vars["RUNTIME_COMMAND"]).to include("$HOME/vendor/mono/bin/mono")
        expect(config_vars["XDG_CONFIG_HOME"]).to include("$HOME/.config")
      end
    end

  end

end