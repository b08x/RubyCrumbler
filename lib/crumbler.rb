#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'fileutils'
require 'glimmer-dsl-libui'
require 'csv'
require 'builder'
require 'tk'
require 'terminal-table'
require 'ruby-progressbar'

# Load configuration
require_relative '../config/settings'

# Load core functionality
require_relative 'crumbler/utils'
require_relative 'crumbler/pipeline'
require_relative 'crumbler/gui'

# The main module for the Crumbler gem.
#
# This gem provides tools for processing and analyzing text from various sources,
# including files, directories, and URLs. It utilizes NLP techniques and other
# libraries for tasks such as cleaning, tokenizing, tagging, lemmatizing, and
# named entity recognition.
#
# @example Basic usage
#   Crumbler.configure do |config|
#     config.output_directory = 'my_output'
#   end
#
#   features = Crumbler::Pipeline::Features.new
#   features.newproject('input.txt', 'my_project')
module Crumbler
  include Logging

  # Generic error class for Crumbler.
  class Error < StandardError; end

  class << self
    # Returns the root directory of the gem.
    # @return [String] The root directory path.
    def root
      File.expand_path('..', __dir__)
    end

    # Returns the current environment (development, test, production).
    # @return [String] The current environment.
    def env
      ENV['CRUMBLER_ENV'] || 'development'
    end

    # Checks if the current environment is development.
    # @return [Boolean] True if the environment is development, false otherwise.
    def development?
      env == 'development'
    end

    # Checks if the current environment is test.
    # @return [Boolean] True if the environment is test, false otherwise.
    def test?
      env == 'test'
    end

    # Checks if the current environment is production.
    # @return [Boolean] True if the environment is production, false otherwise.
    def production?
      env == 'production'
    end

    # Returns the version of the gem.
    # @return [String] The gem version.
    def version
      Config::APP_VERSION
    end

    # Configures the gem with a block.
    # @yield [Configuration] The configuration object.
    def configure
      yield(configuration) if block_given?
    end

    # Returns the configuration object.
    # @return [Configuration] The configuration object.
    def configuration
      @configuration ||= Configuration.new
    end
  end

  # Configuration class for custom settings.
  class Configuration
    # @return [Hash] Custom language models.
    attr_accessor :custom_language_models
    # @return [String] Output directory for processed files.
    attr_accessor :output_directory
    # @return [Integer] Maximum file size allowed for processing.
    attr_accessor :max_file_size

    # Initializes the configuration with default values.
    def initialize
      @custom_language_models = {}
      @output_directory = File.join(Dir.pwd, 'output')
      @max_file_size = Config::MAX_FILE_SIZE
    end
  end

  # Initializes default configuration.
  configure do |config|
    # Add any custom configuration here
  end
end
