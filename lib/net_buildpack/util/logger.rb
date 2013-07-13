require 'fileutils'

module NETBuildpack::Util

  # A very simple and naive logger.  This is only intended to tide us over until a more robust logging solution is
  # exposed to buildpacks
  class Logger

    # The directory that diagnostics are written into
    DIAGNOSTICS_DIRECTORY = '.buildpack-diagnostics'.freeze

    # Creates a new logger
    #
    # @param [String] app_dir the root directory to write diagnostics to
    def initialize(app_dir)
      @diagnostics_directory = File.join app_dir, DIAGNOSTICS_DIRECTORY
      @log_file = File.join @diagnostics_directory, LOG_FILE_NAME

      FileUtils.mkdir_p @diagnostics_directory
      Logger.log(@log_file, @log_file)
    end

    def log(title, data = nil)
      Logger.log @log_file, title, data
    end

    private

    LOG_FILE_NAME = 'buildpack.log'.freeze

    def self.log(file, title, data = nil)
      File.open(file, 'a') do |log|
        log.sync = true

        log.write "#{time_in_millis}: #{title}\n"

        if data
          data_string = data.is_a?(Hash) || data.is_a?(Array) ? data.to_yaml: data.to_s
          data_string.each_line { |line| log.write "\t#{line}" }
        end

        log.write "\n"
      end
    end

    def self.time_in_millis
      Time.now.xmlschema(3).sub(/T/, ' ')
    end

  end

end