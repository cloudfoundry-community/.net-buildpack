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

  describe Mono, :focus => true do

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
            :diagnostics => {:directory => 'fake-diagnostics-dir'},
            :configuration => {}
        ).compile

        mono = File.join(root, 'vendor', 'mono', 'bin', 'mono')
        puts "mono file is: #{mono}"
        expect(File.exists?(mono)).to be_true
      end
    end

  #   it 'adds the JAVA_HOME to java_home' do
  #     Dir.mktmpdir do |root|
  #       JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS_PRE_8)

  #       java_home = ''
  #       OpenJdk.new(
  #           app_dir: '/application-directory',
  #           java_home: java_home,
  #           java_opts: [],
  #           configuration: {}
  #       )

  #       expect(java_home).to eq('.java')
  #     end
  #   end

  #   it 'should fail when ConfiguredItem.find_item fails' do
  #     Dir.mktmpdir do |root|
  #       JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_raise('test error')
  #       expect do
  #         OpenJdk.new(
  #             app_dir: '',
  #             java_home: '',
  #             java_opts: [],
  #             configuration: {}
  #         ).detect
  #       end.to raise_error(/OpenJDK\ JRE\ error:\ test\ error/)
  #     end
  #   end

  #   it 'should add memory options to java_opts' do
  #     Dir.mktmpdir do |root|
  #       JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS_PRE_8)
  #       MemoryHeuristicsOpenJDKPre8.stub(:new).and_return(memory_heuristic)

  #       java_opts = []
  #       OpenJdk.new(
  #           app_dir: '/application-directory',
  #           java_home: '',
  #           java_opts: java_opts,
  #           configuration: {}
  #       ).release

  #       expect(java_opts).to include('opt-1')
  #       expect(java_opts).to include('opt-2')
  #     end
  #   end

  #   it 'adds OnOutOfMemoryError to java_opts' do
  #     Dir.mktmpdir do |root|
  #       JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS_PRE_8)

  #       java_opts = []
  #       OpenJdk.new(
  #           app_dir: root,
  #           java_home: '',
  #           java_opts: java_opts,
  #           configuration: {}
  #       ).release

  #       expect(java_opts).to include("-XX:OnOutOfMemoryError=./#{JavaBuildpack::Diagnostics::DIAGNOSTICS_DIRECTORY}/#{OpenJdk::KILLJAVA_FILE_NAME}")
  #     end
  #   end

  #   it 'places the killjava script (with appropriately substituted content) in the diagnostics directory' do
  #     Dir.mktmpdir do |root|
  #       JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS_PRE_8)
  #       JavaBuildpack::Util::ApplicationCache.stub(:new).and_return(application_cache)
  #       application_cache.stub(:get).with('test-uri').and_yield(File.open('spec/fixtures/stub-java.tar.gz'))

  #       java_opts = []
  #       OpenJdk.new(
  #           app_dir: root,
  #           java_home: '',
  #           java_opts: java_opts,
  #           configuration: {}
  #       ).compile

  #       killjava_content = File.read(File.join(JavaBuildpack::Diagnostics.get_diagnostic_directory(root), OpenJdk::KILLJAVA_FILE_NAME))
  #       expect(killjava_content).to include("#{JavaBuildpack::Diagnostics::LOG_FILE_NAME}")
  #     end
  #   end

  end

end