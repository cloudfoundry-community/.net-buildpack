# Cloud Foundry NET Buildpack
# Copyright (c) 2013 the original author or authors.
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

require 'net_buildpack/util'


module NETBuildpack::Util

  # Run external shell commands, both streaming and logging output
  class RunCommand

		def self.exec(cmd, logger, options = {})
			options[:silent] ||= false
			exit_value = 0
			is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
			if is_windows then 
			  require 'open3'
     	  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          exit_value = wait_thr.value.to_i
          output = "#{cmd}, exit code: #{exit_value}, output: #{stdout.read}\n#{stderr.read}"
          logger.log output
          puts output unless options[:silent]
        end
		  else
	  	  require 'pty'
	  	  logger.log cmd
	  	  puts cmd unless options[:silent]
			  PTY.spawn( cmd ) do |out, in|
			    begin
			      out.each do |line| 
			      	logger.log line
			      	print line unless options[:silent]
			      end
			    rescue Errno::EIO
			    end
			  end
			  exit_value = $?.to_i
			end
			return exit_value
		end

	end
end