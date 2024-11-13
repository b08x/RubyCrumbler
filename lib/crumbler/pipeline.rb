#!/usr/bin/env ruby

require 'pragmatic_tokenizer'
require 'ruby-spacy'

require_relative 'pipeline/cleaner'
require_relative 'pipeline/lemmatizer'
require_relative 'pipeline/ner'
require_relative 'pipeline/tagger'
require_relative 'pipeline/tokenizer'

module Crumbler
  module Pipeline
    class Features
      class Error < StandardError; end
      class FileNotFoundError < Error; end
      class ProcessingError < Error; end
      class ValidationError < Error; end

      attr_reader :cleaner, :tokenizer, :tagger, :lemmatizer, :ner, :processing_stats

      def initialize
        @cleaner = Crumbler::Pipeline::Cleaner.new
        @tokenizer = Crumbler::Pipeline::Tokenizer.new
        @tagger = Crumbler::Pipeline::Tagger.new
        @lemmatizer = Crumbler::Pipeline::Lemmatizer.new
        @ner = Crumbler::Pipeline::Ner.new
        @processing_stats = { processed: 0, failed: 0, warnings: 0 }
      end

      def newproject(input, projectname)
        validate_input!(input)
        setup_project_directory(projectname)
        process_input(input)
      rescue Error => e
        logger.error("Project creation failed: #{e.message}")
        raise
      rescue StandardError => e
        logger.error("Unexpected error in project creation: #{e.message}")
        raise Error, "Failed to create project: #{e.message}"
      end

      private

      def validate_input!(input)
        raise ValidationError, 'Input cannot be empty' if !input || input.strip.empty?

        if File.file?(input)
          validate_file!(input)
        elsif File.directory?(input)
          validate_directory!(input)
        elsif input.match?(URI::DEFAULT_PARSER.make_regexp)
          validate_url!(input)
        else
          raise ValidationError, "Invalid input: #{input}"
        end
      end

      def validate_file!(file_path)
        raise FileNotFoundError, "File not found: #{file_path}" unless File.exist?(file_path)

        unless Config::SUPPORTED_EXTENSIONS.include?(File.extname(file_path).downcase)
          raise ValidationError, "Unsupported file type: #{File.extname(file_path)}"
        end

        if File.size(file_path) > Config::MAX_FILE_SIZE
          raise ValidationError, "File too large: #{File.size(file_path)} bytes (max: #{Config::MAX_FILE_SIZE})"
        end

        return unless File.zero?(file_path)

        raise ValidationError, "File is empty: #{file_path}"
      end

      def validate_directory!(dir)
        raise FileNotFoundError, "Directory not found: #{dir}" unless Dir.exist?(dir)

        filetypes = 'pdf,md,markdown,txt,json,jsonl,html,png,wav,mp3'
        files = Dir.glob(File.join(dir, "**{,/*/**}/*.{#{filetypes}}"))
                   .select { |f| File.file?(f) }

        raise ValidationError, "No files found in directory: #{dir}" if files.empty?

        invalid_files = files.reject { |f| validate_input_file(f) }
        return if invalid_files.empty?

        logger.warn("Invalid files found: #{invalid_files.join(', ')}")
        @processing_stats[:warnings] += invalid_files.size
      end

      def validate_url!(url)
        uri = URI.parse(url)
        raise ValidationError, "Invalid URL: #{url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        raise ValidationError, "Invalid URL format: #{url}"
      end

      def setup_project_directory(projectname)
        @projectname = projectname
        @projectdir = File.join('output', projectname)
        ensure_directory(@projectdir)
      end

      # Helper method to ensure directory exists
      def ensure_directory(dir)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        dir
      end

      # Helper method to validate file
      def validate_input_file(file_path)
        return false unless file_path && File.exist?(file_path)
        return false unless Config::SUPPORTED_EXTENSIONS.include?(File.extname(file_path).downcase)
        return false if File.size(file_path) > Config::MAX_FILE_SIZE

        true
      end

      def process_input(input)
        if File.file?(input)
          process_single_file(input)
        elsif File.directory?(input)
          process_directory(input)
        else
          process_url(input)
        end
      end

      def process_single_file(file_path)
        copy_and_process_file(file_path)
      rescue StandardError => e
        handle_processing_error(file_path, e)
      end

      def process_directory(dir_path)
        filetypes = 'pdf,md,markdown,txt,json,jsonl,html,png,wav,mp3'
        Dir.glob(File.join(dir_path, "**{,/*/**}/*.{#{filetypes}}")).each do |file|
          next unless File.file?(file)

          begin
            copy_and_process_file(file) if validate_input_file(file)
          rescue StandardError => e
            handle_processing_error(file, e)
          end
        end
      end

      def process_url(url)
        content = fetch_url_content(url)
        url_path = url.gsub(%r{^https?://}, '').gsub(%r{[^a-zA-Z0-9/.]}, '_')
        output_path = File.join(@projectdir, url_path)
        ensure_directory(File.dirname(output_path))
        File.write(output_path, content)
        @processing_stats[:processed] += 1
      rescue StandardError => e
        handle_processing_error(url, e)
      end

      def fetch_url_content(url)
        response = URI.open(url)
        doc = Nokogiri::HTML(response)
        doc.search('p', 'text').map(&:text).join('\n')
      rescue OpenURI::HTTPError => e
        raise ProcessingError, "Failed to fetch URL (#{e.message}): #{url}"
      rescue StandardError => e
        raise ProcessingError, "Error processing URL: #{e.message}"
      end

      def copy_and_process_file(file_path)
        relative_path = file_path.start_with?('/') ? file_path[1..-1] : file_path
        output_path = File.join(@projectdir, relative_path)
        ensure_directory(File.dirname(output_path))

        FileUtils.cp(file_path, output_path)
        process_content(file_path, output_path)
        @processing_stats[:processed] += 1
      end

      def process_content(file_path, output_path)
        content = File.read(file_path)
        doc = Nokogiri::HTML(content)
        processed_content = doc.search('p').map(&:text).join('\n')

        # Handle encoding for special characters
        processed_content = processed_content.encode('utf-8', invalid: :replace, undef: :replace)

        File.write(output_path, processed_content)
      rescue Encoding::InvalidByteSequenceError => e
        raise ProcessingError, "Encoding error in file #{file_path}: #{e.message}"
      rescue StandardError => e
        raise ProcessingError, "Failed to process content: #{e.message}"
      end

      def handle_processing_error(source, error)
        logger.error("Error processing #{source}: #{error.message}")
        @processing_stats[:failed] += 1
        raise ProcessingError, "Failed to process #{source}: #{error.message}"
      end

      def cleantext
        validate_project_state!

        Dir.glob(File.join(@projectdir, '**', '*')).each do |file_path|
          next unless File.file?(file_path)

          begin
            process_file_cleaning(file_path)
          rescue StandardError => e
            handle_processing_error(file_path, e)
          end
        end

        log_processing_summary
      end

      def process_file_cleaning(file_path)
        relative_path = file_path[@projectdir.length + 1..-1]
        @filename = File.basename(relative_path, '.*')

        @text2process = File.read(file_path)
        @text2process = @cleaner.process(@text2process)

        output_path = File.join(File.dirname(file_path), "#{@filename}_cl.txt")
        ensure_directory(File.dirname(output_path))
        File.write(output_path, @text2process)

        logger.info("Successfully cleaned file: #{relative_path}")
        @processing_stats[:processed] += 1
      end

      def validate_project_state!
        raise Error, 'Project directory not set' unless @projectdir
        raise Error, "Project directory not found: #{@projectdir}" unless Dir.exist?(@projectdir)
      end

      def log_processing_summary
        logger.info('Processing completed:')
        logger.info("  Processed: #{@processing_stats[:processed]}")
        logger.info("  Failed: #{@processing_stats[:failed]}")
        logger.info("  Warnings: #{@processing_stats[:warnings]}")
      end

      def normalize(contractions = false, language = 'EN', lowercase = false)
        validate_project_state!
        validate_language!(language)

        files = get_files_to_process

        files.each do |file|
          process_file_normalization(file, contractions, language, lowercase)
        rescue StandardError => e
          handle_processing_error(file, e)
        end

        log_processing_summary
      end

      def get_files_to_process
        Dir.glob(File.join(@projectdir, '**', '*'))
           .select { |f| File.file?(f) }
           .sort_by { |f| File.mtime(f) }
           .take(@filenumber || 1)
      end

      def validate_language!(language)
        return if Config::SUPPORTED_LANGUAGES.key?(language.upcase)

        raise ValidationError, "Unsupported language: #{language}"
      end

      def process_file_normalization(file_path, contractions, language, lowercase)
        return unless File.exist?(file_path)

        relative_path = file_path[@projectdir.length + 1..-1]
        @filename = File.basename(relative_path, '.*')
        @text2process = File.read(file_path)

        @text2process = @cleaner.normalize(@text2process,
                                           contractions: contractions,
                                           language: language,
                                           lowercase: lowercase)

        suffix = lowercase ? '_nl' : '_n'
        output_path = File.join(File.dirname(file_path), "#{@filename}#{suffix}.txt")
        ensure_directory(File.dirname(output_path))
        File.write(output_path, @text2process)

        logger.info("Successfully normalized file: #{relative_path}")
        @processing_stats[:processed] += 1
      end
    end
  end
end
