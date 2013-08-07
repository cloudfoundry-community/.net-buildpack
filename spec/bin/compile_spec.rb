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
require 'open3'
require 'tmpdir'

describe 'compile script', :integration do
	it 'should return zero if success' do # WARNING.  This takes ages to run the first time since it downloads a 60MB mono runtime tar.gz
    Dir.mktmpdir do |root|
      FileUtils.cp_r 'spec/fixtures/integration_valid/.', root
      cache_dir =  File.join Dir.tmpdir, ".net_buildpack_cache_dir"
      FileUtils.mkdir_p cache_dir

      with_memory_limit('1G') do
        Open3.popen3("bin/compile #{root} #{cache_dir}") do |stdin, stdout, stderr, wait_thr|
        	 exit_value = wait_thr.value
        	 puts "#{stdout.read}\n#{stderr.read}" if exit_value != 0
        	 expect(exit_value).to be_success
        end
      end
      # puts `cat #{root}/.buildpack-diagnostics/buildpack.log`
      # puts `tree -a #{root}`
    end
  end

  def with_memory_limit(memory_limit)
    previous_value = ENV['MEMORY_LIMIT']
    begin
      ENV['MEMORY_LIMIT'] = memory_limit
      yield
    ensure
      ENV['MEMORY_LIMIT'] = previous_value
    end
  end
end