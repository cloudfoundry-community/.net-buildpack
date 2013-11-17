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
require 'net_buildpack/container/procfile'

module NETBuildpack::Container

  describe Procfile do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    it 'should detect with Procfile' do
      detected = Procfile.new(
          app_dir: 'spec/fixtures/procfile'
      ).detect

      expect(detected).to be_true
    end

    it 'should return forego command' do
      Dir.mktmpdir do |root|

        lib_directory = File.join(root, 'vendor')
        Dir.mkdir lib_directory

        start_script = { :init => [], :run_command => "" }

        Procfile.new(
            app_dir: root,
            lib_directory: lib_directory,
            start_script: start_script
        ).release

        expect(start_script[:run_command]).to include('/app/vendor/forego start -p $PORT')
      end
    end

    #otherwise CF runtime will use the web: element as the start command rather than the 'forego start' command we specify
    it 'web: element in Procfile should be changed to _web:' do
      Dir.mktmpdir do |root|
        procfile = create_procfile root

        container = Procfile.new(
            app_dir: root
        )

        container.stub(:download) #just ignore

        container.compile

        expect(File.read(procfile)).to eq('_web: mono --server myapp-web.exe')
      end
    end

    def create_procfile(app_dir)
      procfile = File.join app_dir, 'Procfile'
      File.open(procfile, 'w') { |f| f.write("web: mono --server myapp-web.exe")}
      procfile
    end
  end

end