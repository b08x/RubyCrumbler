#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'fileutils'
require 'ruby-spacy'
require 'glimmer-dsl-libui'
require 'csv'
require 'builder'
require 'tk'
require 'terminal-table'
require 'ruby-progressbar'
require 'pragmatic_tokenizer'

# Load configuration
require_relative '../config/settings'

# Load core functionality
require_relative 'utils/logging'

require_relative 'ruby_crumbler/pipeline/features'
require_relative 'ruby_crumbler/gui/crumbler_gui'

module RubyCrumbler
  include Logging
  class Error < StandardError; end

  class << self
    def root
      File.expand_path('..', __dir__)
    end

    def env
      ENV['RUBY_CRUMBLER_ENV'] || 'development'
    end

    def development?
      env == 'development'
    end

    def test?
      env == 'test'
    end

    def production?
      env == 'production'
    end

    def version
      Config::APP_VERSION
    end

    def configure
      yield(configuration) if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end

  # Configuration class for custom settings
  class Configuration
    attr_accessor :custom_language_models,
                  :output_directory,
                  :max_file_size

    def initialize
      @custom_language_models = {}
      @output_directory = File.join(Dir.pwd, 'output')
      @max_file_size = Config::MAX_FILE_SIZE
    end
  end

  # Initialize default configuration
  configure do |config|
    # Add any custom configuration here
  end
end
