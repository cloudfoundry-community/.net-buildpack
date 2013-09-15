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

    it 'returns an error exit code' do
      exit_value = NETBuildpack::Util::RunCommand.exec("ls /this/doesnt/exist/foo/bar.baz", logger, { :silent => true })
      expect(exit_value).to eq(1)
    end

    it 'streams output from long running processes' do
      exit_value = NETBuildpack::Util::RunCommand.exec("echo 'Sleeping...' && sleep 0.1 && echo 'Done.'", logger, { :silent => false })
      expect(exit_value).to eq(0)
    end


  end

end