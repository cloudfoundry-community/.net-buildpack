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
require 'net_buildpack/framework/app_settings_auto_reconfiguration'

module NETBuildpack::Framework

  describe AppSettingsAutoReconfiguration do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    it 'should detect with exe.config' do

      detected = AppSettingsAutoReconfiguration.new(
          app_dir: 'spec/fixtures/sample_commandline_app/bin'
      ).detect

      expect(detected).to eq('app_settings_auto_reconfiguration')
    end

    it 'should detect with Web.config' do

      detected = AppSettingsAutoReconfiguration.new(
          app_dir: 'spec/fixtures/sample_asp_net_mvc'
      ).detect

      expect(detected).to eq('app_settings_auto_reconfiguration')
    end

    it '[on compile] should copy additional libraries to the vendor directory' do
      Dir.mktmpdir do |root|

        FileUtils.cp_r 'spec/fixtures/sample_commandline_app/bin/.', root

        AppSettingsAutoReconfiguration.new(
            app_dir: root
        ).compile

        location = File.join( root, 'vendor', 'AppSettingsAutoReconfiguration.exe' )

        expect(File.exists?(location)).to be true
      end
    end

    it '[on release] should add AppSettingsAutoReconfiguration.exe call to startup script init section' do
      start_script = { :init => [], :run => "" }

      detected = AppSettingsAutoReconfiguration.new(
         app_dir: 'spec/fixtures/sample_commandline_app/bin',
         start_script: start_script
      ).release

      expect(start_script[:init]).to \
        include('mono $HOME/vendor/AppSettingsAutoReconfiguration.exe $HOME/SampleCommandlineApp.exe.Config')

    end

  end

end