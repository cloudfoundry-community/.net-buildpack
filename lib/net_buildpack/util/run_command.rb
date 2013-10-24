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
require 'tempfile'


module NETBuildpack::Util

  # Run external shell commands, both streaming and logging output
  class RunCommand

		def self.exec(cmd, logger, options = {})
			options[:silent] ||= false
			options[:env] ||= {}
			exit_value = 0
			output = "With ENV:\n#{options[:env].inspect}\n\nexec '#{cmd}':\n\n"
	  	puts cmd unless options[:silent]
			is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
			if is_windows then 
			  require 'open3'
     	  Open3.popen3(options[:env], cmd) do |stdin, stdout, stderr, wait_thr|
          exit_value = wait_thr.value.to_i
          output = "#{cmd}, exit code: #{exit_value}, output: #{stdout.read}\n#{stderr.read}"
          logger.log output
          puts output unless options[:silent]
        end
		  else
	  	  require 'pty'
	  	  #Wrap bash commands in a script so that PTY.spawn will run them.
	  	  unless File.exists?(cmd)
	  	  	cmd_file = Tempfile.new('net_buildpack_run_command.sh')
	  	  	cmd_file.write("#!/usr/bin/env bash\n")
	  	  	cmd_file.write(cmd)
	  	  	cmd_file.close
	  	  	cmd = cmd_file.path
	  	  	File.chmod(0744, cmd)
	  	  end
			  PTY.spawn(options[:env], cmd ) do |stdout_and_err, stdin, pid| 
			  	begin
			      stdout_and_err.each do |line| 
			      	output += line
			      	print line unless options[:silent]
			      end
			    rescue Errno::EIO
			    	#ignore - see http://stackoverflow.com/questions/10238298/ruby-on-linux-pty-goes-away-without-eof-raises-errnoeio
		      ensure
		      	Process.wait(pid)
		      end
			  end
			  logger.log output
			  exit_value = $?.exitstatus
			end
			return exit_value
		end

	end
end