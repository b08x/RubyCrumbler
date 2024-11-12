#!/usr/bin/env ruby
# frozen_string_literal: true

module RubyCrumbler
  module Config
    # Application version
    APP_VERSION = '1.0.0'

    # Maximum file size in bytes (50MB)
    MAX_FILE_SIZE = 52_428_800

    # Supported languages
    SUPPORTED_LANGUAGES = {
      'EN' => 'en_core_web_lg',
      'DE' => 'de_core_news_lg'
    }.freeze

    # File extensions that can be processed
    SUPPORTED_EXTENSIONS = %w[.txt .html .xml .md .markdown .pdf .mp3 .wav].freeze

    # Output formats
    OUTPUT_FORMATS = %w[txt csv xml].freeze

    # Default settings
    DEFAULTS = {
      output_directory: Dir.pwd,
      language: 'EN',
      max_file_size: MAX_FILE_SIZE,
      log_level: :info
    }.freeze

    class << self
      # Returns the root directory of the application
      #
      # @return [String] The root directory path
      def root
        @root ||= File.expand_path('..', __dir__)
      end

      # Returns the current environment
      #
      # @return [String] The current environment (development, test, or production)
      def env
        ENV['RUBY_ENV'] || 'development'
      end

      # Checks if the current environment is development
      #
      # @return [Boolean] True if in development environment
      def development?
        env == 'development'
      end

      # Checks if the current environment is test
      #
      # @return [Boolean] True if in test environment
      def test?
        env == 'test'
      end

      # Checks if the current environment is production
      #
      # @return [Boolean] True if in production environment
      def production?
        env == 'production'
      end

      # Validates a file for processing
      #
      # @param file_path [String] Path to the file
      # @return [Boolean] True if file is valid
      # @raise [ArgumentError] If file is invalid
      def validate_file!(file_path)
        raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)

        unless SUPPORTED_EXTENSIONS.include?(File.extname(file_path).downcase)
          raise ArgumentError, "Unsupported file type: #{File.extname(file_path)}"
        end

        if File.size(file_path) > MAX_FILE_SIZE
          raise ArgumentError, "File too large: #{File.size(file_path)} bytes (max: #{MAX_FILE_SIZE} bytes)"
        end

        true
      end

      # Validates a language code
      #
      # @param lang [String] Language code (EN or DE)
      # @return [Boolean] True if language is supported
      # @raise [ArgumentError] If language is not supported
      def validate_language!(lang)
        raise ArgumentError, "Unsupported language: #{lang}" unless SUPPORTED_LANGUAGES.key?(lang.upcase)

        true
      end

      # Returns the spaCy model name for a language
      #
      # @param lang [String] Language code (EN or DE)
      # @return [String] The spaCy model name
      def language_model(lang)
        SUPPORTED_LANGUAGES[lang.upcase]
      end

      # Ensures a directory exists and is writable
      #
      # @param dir [String] Directory path
      # @return [Boolean] True if directory is valid
      # @raise [ArgumentError] If directory is invalid
      def validate_directory!(dir)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

        raise ArgumentError, "Directory not writable: #{dir}" unless File.writable?(dir)

        true
      end
    end
  end
end
