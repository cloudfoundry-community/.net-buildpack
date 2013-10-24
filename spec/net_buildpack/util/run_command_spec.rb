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
require 'net_buildpack/util/run_command'

module NETBuildpack::Util

  describe RunCommand do

    let(:logger) { double('logger', log: nil) }

    it 'returns a success error code' do
      exit_value = NETBuildpack::Util::RunCommand.exec("echo 'Hello world'", logger, { :silent => true })
      expect(exit_value).to eq(0)
    end

    it 'returns an error exit code for a long running erroring command' do
      exit_value = NETBuildpack::Util::RunCommand.exec("sleep 0.2 && exit 1", logger, { :silent => true })
      expect(exit_value).to eq(1)
    end

    it 'returns an error exit code for a short running erroring command' do
      exit_value = NETBuildpack::Util::RunCommand.exec("exit 2", logger, { :silent => true })
      expect(exit_value).to eq(2)
    end

    it 'streams output from long running processes' do
      exit_value = NETBuildpack::Util::RunCommand.exec("echo 'Sleeping...' && sleep 0.1 && echo 'Done.'", logger, { :silent => false })
      expect(exit_value).to eq(0)
    end

    it 'can be run with a custom ENV' do
      logger.should_receive(:log) do |msg|
        msg.should include('FOO:BAR')
      end

      exit_value = NETBuildpack::Util::RunCommand.exec("echo FOO:$FOO", logger, { :silent => true, :env => {"FOO" => "BAR"} })
      expect(exit_value).to eq(0)
    end

    it 'custom ENV vars can reference other ENV vars' do
      logger.should_receive(:log) do |msg|
        msg.should include('ENV2:ONE,TWO')
      end

      exit_value = NETBuildpack::Util::RunCommand.exec("echo ENV2:$ENV2", logger, { :silent => true, :env => {"ENV1" => "ONE", "ENV2" => "$ENV1,TWO"} })
      expect(exit_value).to eq(0)
    end

  end

end