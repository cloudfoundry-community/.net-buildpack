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
require 'open3'

module NETBuildpack

  APP_DIR = 'test-app-dir'.freeze

  describe Buildpack do

    let(:stub_container1) { double('StubContainer1', detect: nil) }
    let(:stub_container2) { double('StubContainer2', detect: nil) }
    let(:stub_framework1) { double('StubFramework1', detect: nil) }
    let(:stub_framework2) { double('StubFramework2', detect: nil) }
    let(:stub_runtime1) { double('StubRuntime1', detect: nil) }
    let(:stub_runtime2) { double('StubRuntime2', detect: nil) }

    before do
      YAML.stub(:load_file).with(File.expand_path('config/components.yml')).and_return(
          'containers' => ['Test::StubContainer1', 'Test::StubContainer2'],
          'frameworks' => ['Test::StubFramework1', 'Test::StubFramework2'],
          'runtimes' => ['Test::StubRunTime1', 'Test::StubRunTime2']
      )

      Test::StubContainer1.stub(:new).and_return(stub_container1)
      Test::StubContainer2.stub(:new).and_return(stub_container2)

      Test::StubFramework1.stub(:new).and_return(stub_framework1)
      Test::StubFramework2.stub(:new).and_return(stub_framework2)

      Test::StubRunTime1.stub(:new).and_return(stub_runtime1)
      Test::StubRunTime2.stub(:new).and_return(stub_runtime2)

      $stderr = StringIO.new
      tmpdir = Dir.tmpdir
      diagnostics_directory = File.join(tmpdir, NETBuildpack::Util::Logger::DIAGNOSTICS_DIRECTORY)
      FileUtils.rm_rf diagnostics_directory
    end

    it '[on detect] should return no detections if no runtime can run an application' do
      stub_container1.stub(:detect).and_return('stub-container-1')

      detected = with_buildpack { |buildpack| buildpack.detect }
      expect(detected).to eq([])
    end

    it '[on detect] should return no detections if no container can run an application' do
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')

      detected = with_buildpack { |buildpack| buildpack.detect }
      expect(detected).to eq([])
    end

    it '[on compile] should raise an error if more than one runtime can run an application' do
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')
      stub_runtime2.stub(:detect).and_return('stub-runtime-2')

      with_buildpack { |buildpack| expect { buildpack.compile }.to raise_error(/More than one runtime can run the application/) }
    end

    it '[on compile] should raise an error if no container can run an application' do
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')
      with_buildpack { |buildpack| expect { buildpack.compile }.to raise_error(/No container can run the application/) }
    end

    it '[on compile] should raise an error if more than one container can run an application' do
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_container2.stub(:detect).and_return('stub-container-2')

      with_buildpack { |buildpack| expect { buildpack.compile }.to raise_error(/More than one container can run the application/) }
    end

    it '[on compile] should call compile on matched components' do
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_framework1.stub(:detect).and_return('stub-framework-1')
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')

      stub_runtime1.should_receive(:compile)
      stub_runtime2.should_not_receive(:compile)      
      stub_container1.should_receive(:compile)
      stub_container2.should_not_receive(:compile)
      stub_framework1.should_receive(:compile)
      stub_framework2.should_not_receive(:compile)

      with_buildpack { |buildpack| buildpack.compile }
    end

    it '[on release] should call release on matched components' do
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_framework1.stub(:detect).and_return('stub-framework-1')
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')

      stub_runtime1.stub(:release).and_return('start.sh')

      stub_container1.should_receive(:release)
      stub_container2.should_not_receive(:release)
      stub_framework1.should_receive(:release)
      stub_framework2.should_not_receive(:release)
      stub_runtime1.should_receive(:release)
      stub_runtime2.should_not_receive(:release)

      payload = with_buildpack { |buildpack| buildpack.release }

      expect(payload).to eq({ 'addons' => [], 'config_vars' => {}, 'default_process_types' => { 'web' => 'start.sh' } }.to_yaml)
    end

    it '[on release] should write config_vars to profile.d/net_buildpack_env.sh during release' do
      stub_framework1.stub(:detect).and_return('stub-framework-1')
      stub_framework1.stub(:release).and_return(nil)

      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_container1.stub(:release).and_return('test-command')

      stub_runtime1.stub(:detect).and_return('stub-runtime-1')
      stub_runtime1.stub(:release)

      Dir.mktmpdir do |root|
        buildpack = NETBuildpack::Buildpack.new(File.join(root, APP_DIR))
        buildpack.release 
        net_buildpack_env = File.read(File.join(root, APP_DIR, ".profile.d", "net_buildpack_env.sh"))

        expect(net_buildpack_env).to include("export BUILDPACK=\".net-buildpack\"")
      end
    end

    it '[on detect] should load configuration files matching detected class names' do
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')
      File.stub(:exists?).with(/.*buildpack\/hooks.*/).and_return(false)
      File.stub(:exists?).with(File.expand_path('config/stubruntime1.yml')).and_return(true)
      File.stub(:exists?).with(File.expand_path('config/stubruntime2.yml')).and_return(false)
      File.stub(:exists?).with(File.expand_path('config/stubframework1.yml')).and_return(false)
      File.stub(:exists?).with(File.expand_path('config/stubframework2.yml')).and_return(false)
      File.stub(:exists?).with(File.expand_path('config/stubcontainer1.yml')).and_return(false)
      File.stub(:exists?).with(File.expand_path('config/stubcontainer2.yml')).and_return(false)
      YAML.stub(:load_file).with(File.expand_path('config/stubruntime1.yml')).and_return('x' => 'y')

      with_buildpack { |buildpack| buildpack.detect }
    end

    it '[on detect] should call pre_detect and post_detect hook scripts on detect' do
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')
      stub_container1.stub(:detect).and_return('stub-container-1')

      with_buildpack { |buildpack| 
      	buildpack.should_receive(:run_hook).with("pre_detect", {:silent => true}).ordered
      	buildpack.should_receive(:run_hook).with("post_detect", {:silent => true}).ordered

      	buildpack.detect 
      }
    end

    it '[on compile] should call pre_compile and post_compile hook scripts on compile' do
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_framework1.stub(:detect).and_return('stub-framework-1')
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')

      stub_container1.stub(:compile)
      stub_framework1.stub(:compile)
      stub_runtime1.stub(:compile)

      with_buildpack { |buildpack| 
      	buildpack.should_receive(:run_hook).with("pre_compile").ordered
      	buildpack.should_receive(:run_hook).with("pre_runtime_compile").ordered
      	buildpack.should_receive(:run_hook).with("post_runtime_compile").ordered
      	buildpack.should_receive(:run_hook).with("post_compile").ordered

      	buildpack.compile 
      }
    end

    it '[on release] should call pre_release and post_release hook scripts on release' do
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_framework1.stub(:detect).and_return('stub-framework-1')
      stub_runtime1.stub(:detect).and_return('stub-runtime-1')

      stub_framework1.stub(:release)
      stub_runtime1.stub(:release)
      stub_container1.stub(:release).and_return('test-command')

      with_buildpack { |buildpack| 
      	buildpack.should_receive(:run_hook).with("pre_release", {:silent => true}).ordered
      	buildpack.should_receive(:run_hook).with("post_release", {:silent => true}).ordered

      	buildpack.release 
      }
    end

    #FIXME - need to figure out how to fail if Open3.popen3 isn't called at all
    it 'should run hook script if it exists' do

    	NETBuildpack::Util::RunCommand.stub(:exec)\
    		.with(/.*\/test-app-dir\/\.buildpack\/hooks\/test_hook.*/, \
    				  an_instance_of(NETBuildpack::Util::Logger), \
    				  be_a(Hash))\
    		.and_return(0)

      with_buildpack { |buildpack| 
      	buildpack.stub(:hook_exists?).and_return(true)
      	buildpack.stub(:convert_dos_to_unix_line_endings)

      	result = buildpack.send(:run_hook, "test_hook") 
      	expect(result).to eq(0)
      }

    end

    def with_buildpack(&block)
      Dir.mktmpdir do |root|
        buildpack = NETBuildpack::Buildpack.new(File.join(root, APP_DIR))
        block.call buildpack
      end
    end

  end

end

module Test
  class StubContainer1
  end

  class StubContainer2
  end

  class StubRunTime1
  end

  class StubRunTime2
  end

  class StubFramework1
  end

  class StubFramework2
  end
end