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
    end

    it 'should detect with id of mono-<version>' do
      Dir.mktmpdir do |root|
        NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)

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

    it 'should extract Mono from a GZipped TAR' do
      Dir.mktmpdir do |root|
        NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)
        NETBuildpack::Util::ApplicationCache.stub(:new).and_return(application_cache)
        application_cache.stub(:get).with('test-uri').and_yield(File.open('spec/fixtures/stub-mono.tar.gz'))
        stub_certs_txt = File.join root, 'stub-mozillacertdata.txt' 
        FileUtils.touch stub_certs_txt
        application_cache.stub(:get).with(NETBuildpack::Runtime::Mono::MOZILLA_CERTS_URL).and_yield(File.open(stub_certs_txt))

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

    it 'places the downloaded mozilla_certsdata.txt vendor/mono directory' do
      Dir.mktmpdir do |root|
        NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)
        NETBuildpack::Util::ApplicationCache.stub(:new).and_return(application_cache)
        application_cache.stub(:get).with('test-uri').and_yield(File.open('spec/fixtures/stub-mono.tar.gz'))
        stub_certs_txt = File.join root, 'stub-mozillacertdata.txt' 
        FileUtils.touch stub_certs_txt
        application_cache.stub(:get).with(NETBuildpack::Runtime::Mono::MOZILLA_CERTS_URL).and_yield(File.open(stub_certs_txt))

        detected = Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).compile


        mono_certs = File.join(root, 'vendor', 'mono', 'mozilla_certsdata.txt')
        expect(File.exists?(mono_certs)).to be_true

        mono_setup = File.join(root, 'vendor', 'mono', 'bin', 'setup_mono')
        expect(File.exists?(mono_setup)).to be_true
        mono_setup_content = File.read(mono_setup)
        expect(mono_setup_content).to include("--import --sync --file")
      end
    end

    it 'adds setup_mono to run_command' do
      Dir.mktmpdir do |root|
        NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)

        run_command = ""
        Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => run_command,
            :config_vars => {},
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).release

        expect(run_command).to include("setup_mono")
      end
    end

    it 'adds correct env vars to config_vars ' do
      Dir.mktmpdir do |root|
        NETBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)

        config_vars = {}
        Mono.new(
            :app_dir => root,
            :runtime_home => '',
            :runtime_command => '',
            :config_vars => config_vars,
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).release

        expect(config_vars["LD_LIBRARY_PATH"]).to include("/app/vendor/mono/lib")
        expect(config_vars["DYLD_LIBRARY_FALLBACK_PATH"]).to include("/app/vendor/mono/lib")
        expect(config_vars["C_INCLUDE_PATH"]).to include("/app/vendor/mono/include")
        expect(config_vars["ACLOCAL_PATH"]).to include("/app/vendor/mono/share/aclocal")
        expect(config_vars["PKG_CONFIG_PATH"]).to include("/app/vendor/mono/lib/pkgconfig")
        expect(config_vars["PATH"]).to include("/app/vendor/mono/bin")
      end
    end

  end

end