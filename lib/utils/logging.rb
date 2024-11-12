#!/usr/bin/env ruby
# frozen_string_literal: true

module Logging
  module_function

  require 'logger'
  require 'fileutils'

  # The directory where log files will be stored.
  LOG_DIR = File.expand_path(File.join(__dir__, '../..', 'log'))

  # The default log level.
  LOG_LEVEL = Logger::INFO

  # The maximum size of a log file in bytes (2MB).
  LOG_MAX_SIZE = 2_145_728

  # The maximum number of log files to keep.
  LOG_MAX_FILES = 100

  # A hash to store loggers for different classes and methods.
  @loggers = {}

  # Ensure log directory exists
  FileUtils.mkdir_p(LOG_DIR) unless Dir.exist?(LOG_DIR)

  # Returns the logger for the current class and method.
  #
  # @return [Logger] The logger object.
  def logger
    # Get the name of the current class.
    classname = self.class.name

    # Get the name of the current method.
    methodname = caller(1..1).first[/`([^']*)'/, 1]

    # Get the logger for the current class, or create a new one if it doesn't exist.
    @logger ||= Logging.logger_for(classname, methodname)

    # Set the progname of the logger to include the class and method name.
    @logger.progname = "#{classname}##{methodname}"

    # Return the logger object.
    @logger
  end

  class << self
    # Returns the default log level, considering environment.
    #
    # @return [Integer] The log level.
    def log_level
      case ENV['RUBY_ENV']
      when 'production'
        Logger::INFO
      when 'test'
        Logger::ERROR
      else
        Logger::DEBUG
      end
    end

    # Returns the logger for the specified class and method.
    #
    # @param classname [String] The name of the class.
    # @param methodname [String] The name of the method.
    #
    # @return [Logger] The logger object.
    def logger_for(classname, methodname)
      # Get the logger for the specified class, or create a new one if it doesn't exist.
      @loggers[classname] ||= configure_logger_for(classname, methodname)
    end

    # Configures a logger for the specified class and method.
    #
    # @param classname [String] The name of the class.
    # @param methodname [String] The name of the method.
    #
    # @return [Logger] The configured logger object.
    def configure_logger_for(classname, methodname)
      # Get the current date in YYYY-MM-DD format.
      current_date = Time.now.strftime('%Y-%m-%d')

      # Construct the log file path.
      log_file = File.join(LOG_DIR, "crumbler-#{current_date}.log")

      # Create a new logger object with daily rotation.
      logger = Logger.new(log_file, LOG_MAX_FILES, LOG_MAX_SIZE)

      # Set the log level based on environment.
      logger.level = log_level

      # Configure the log format.
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} -- #{classname}##{methodname}: #{msg}\n"
      end

      # Return the configured logger object.
      logger
    end

    # Clear all loggers (useful for testing).
    #
    # @return [void]
    def clear_loggers!
      @loggers = {}
    end
  end
end
