#!/usr/bin/env ruby
require_relative 'cleaner'
require_relative 'tokenizer'
require_relative 'tagger'
require_relative 'lemmatizer'
require_relative 'ner'
module RubyCrumbler
  module Pipeline
    class Features
      class Error < StandardError; end
      class FileNotFoundError < Error; end
      class ProcessingError < Error; end
      class ValidationError < Error; end

      include Logging

      def initialize
        @cleaner = Cleaner.new
        @tokenizer = Tokenizer.new
        @tagger = Tagger.new
        @lemmatizer = Lemmatizer.new
        @ner = Ner.new
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

        files = Dir.glob(File.join(dir, '*'))
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
        @projectdir = create_unique_directory(projectname)
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

      def create_unique_directory(base_name)
        dir_name = base_name
        counter = 1
        while Dir.exist?(dir_name)
          dir_name = "#{base_name}#{counter}"
          counter += 1
        end
        dir_name
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
        Dir.glob(File.join(dir_path, '*')).each do |file|
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
        output_path = File.join(@projectdir, "#{File.basename(url, '.*')}.txt")
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
        FileUtils.cp(file_path, @projectdir)
        process_content(file_path)
        @processing_stats[:processed] += 1
      end

      def process_content(file_path)
        content = File.read(file_path)
        doc = Nokogiri::HTML(content)
        processed_content = doc.search('p').map(&:text).join('\n')

        # Handle encoding for special characters
        processed_content = processed_content.encode('utf-8', invalid: :replace, undef: :replace)

        output_path = File.join(@projectdir, File.basename(file_path))
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

      # Enhanced version of cleantext with better error handling
      def cleantext
        validate_project_state!

        Dir.foreach(@projectdir) do |filename|
          next if ['.', '..'].include?(filename)

          begin
            process_file_cleaning(filename)
          rescue StandardError => e
            handle_processing_error(filename, e)
          end
        end

        log_processing_summary
      end

      def process_file_cleaning(filename)
        @filename = File.basename(filename, '.*')
        file_path = find_input_file(@filename)

        raise FileNotFoundError, "No matching file found for: #{@filename}" unless file_path

        @text2process = File.read(file_path)
        @text2process = @cleaner.process(@text2process)

        output_path = File.join(@projectdir, "#{@filename}_cl.txt")
        File.write(output_path, @text2process)

        logger.info("Successfully cleaned file: #{filename}")
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

      # Add this to your existing normalize method
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
        Dir.glob(File.join(@projectdir, '*'))
           .select { |f| File.file?(f) }
           .sort_by { |f| File.mtime(f) }
           .take(@filenumber || 1)
      end

      def validate_language!(language)
        return if Config::SUPPORTED_LANGUAGES.key?(language.upcase)

        raise ValidationError, "Unsupported language: #{language}"
      end

      def process_file_normalization(file, contractions, language, lowercase)
        return unless File.exist?(file)

        @filename = File.basename(file, '.*')
        @text2process = File.read(file)

        @text2process = @cleaner.normalize(@text2process,
                                           contractions: contractions,
                                           language: language,
                                           lowercase: lowercase)

        suffix = lowercase ? '_nl' : '_n'
        output_path = File.join(@projectdir, "#{@filename}#{suffix}.txt")
        File.write(output_path, @text2process)

        logger.info("Successfully normalized file: #{@filename}")
        @processing_stats[:processed] += 1
      end
    end
  end
end
