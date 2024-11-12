#!/usr/bin/env ruby
require_relative 'cleaner'
require_relative 'tokenizer'
require_relative 'tagger'
require_relative 'lemmatizer'
require_relative 'ner'

module RubyCrumbler
  module Pipeline
    class Features
      def initialize
        @cleaner = Cleaner.new
        @tokenizer = Tokenizer.new
        @tagger = Tagger.new
        @lemmatizer = Lemmatizer.new
        @ner = Ner.new
      end

      # multidir function is automatically called, if a folder is used for input
      def multidir(directory)
        directory = @projectdir
        @filenumber = Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count
        print @filenumber
        Dir.foreach(directory) do |filename|
          next if ['.', '..'].include?(filename)

          puts "working on #{filename}"
          @filenamein = filename
          @filename = File.basename(filename, '.*')
          first = Nokogiri::HTML(File.open("#{@projectdir}/#{@filenamein}"))
          doc = first.search('p').map(&:text)
          # encode doc to correct encoding for German special characters
          doc = doc.join('').encode('iso-8859-1').force_encoding('utf-8')
          File.write("#{@projectdir}/#{@filename}", doc)
        end
      end

      # create a new folder and copy chosen file to it OR copy all files in chosen directory to it OR write file from website into it
      def newproject(input, projectname)
        @input = input
        @projectname = projectname
        @filename = File.basename(@input)
        if !Dir.exist?("#{@projectname}")
          @projectdir = "#{@projectname}"
        else
          i = 1
          i += 1 while Dir.exist?("#{@projectname}" + i.to_s)
          @projectdir = "#{@projectname}" + i.to_s
        end
        Dir.mkdir(@projectdir)
        if File.file?(@input)
          FileUtils.cp(@input, @projectdir)
          first = Nokogiri::HTML(File.open(@input))
          doc = first.search('p').map(&:text)
          @filenumber = 1
          # encode doc to correct encoding for German specific characters
          doc = doc.join('').encode('iso-8859-1').force_encoding('utf-8')
          File.write("#{@projectdir}/#{@filename}", doc)
        elsif File.directory?(@input)
          FileUtils.cp_r Dir.glob(@input + '/*.*'), @projectdir
          multidir(@projectdir)
        else
          first = Nokogiri::HTML(URI.open(@input))
          doc = first.search('p', 'text').map(&:text)
          @filenumber = 1
          File.write("#{@projectdir}/#{@filename}.txt", doc)
        end
      end

      # Modified cleantext method in features.rb
      def cleantext
        Dir.foreach(@projectdir) do |filename|
          next if ['.', '..'].include?(filename)

          puts "working on #{filename}"
          @filename = File.basename(filename, '.*')

          # Find the actual file instead of using wildcard
          file_path = Dir.glob(File.join(@projectdir, "#{@filename}.*")).first

          if file_path && File.exist?(file_path)
            @text2process = File.read(file_path)
            @text2process = @cleaner.process(@text2process)
            output_path = File.join(@projectdir, "#{@filename}_cl.txt")
            File.write(output_path, @text2process)
            p @text2process
          else
            logger.warn("File not found for cleaning: #{@filename}")
          end
        end
      end

      # Modified normalize method
      def normalize(contractions = false, language = 'EN', lowercase = false)
        files = Dir.glob(File.join(@projectdir, '*'))
                   .select { |f| File.file?(f) }
                   .sort_by { |f| File.mtime(f) }
                   .take(@filenumber)

        files.each do |file|
          next unless File.exist?(file) # Extra safety check

          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"

          begin
            @text2process = File.read(file)
            @text2process = @cleaner.normalize(@text2process,
                                               contractions: contractions,
                                               language: language,
                                               lowercase: lowercase)

            suffix = lowercase ? '_nl' : '_n'
            output_path = File.join(@projectdir, "#{@filename}#{suffix}.txt")
            File.write(output_path, @text2process)
            p @text2process
          rescue StandardError => e
            logger.error("Error processing file #{file}: #{e.message}")
          end
        end
      end

      # Helper method to safely find input files
      def find_input_file(filename)
        Dir.glob(File.join(@projectdir, "#{filename}.*")).first
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

      # tokenize the input text and show number of tokens
      def tokenizer(language)
        Dir.glob(@projectdir + '/*.*').max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"
          @text2process = File.read(file)

          tokens = @tokenizer.process(@text2process, language: language)
          count = tokens.length

          File.write("#{@projectdir}/#{@filename}_tok.txt", tokens)
          puts("Total number of tokens: #{count}")
        end
      end

      # clean input from stopwords
      def stopwordsclean(language)
        Dir.glob(@projectdir + '/*.*').max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"
          @text2process = File.read(file)

          tokens = @tokenizer.process(@text2process, language: language, remove_stopwords: true)
          File.write("#{@projectdir}/#{@filename}_nost.txt", tokens)
        end
      end

      # convert input tokens to their respective lemma
      def lemmatizer(language)
        Dir.glob(@projectdir + '/*.*').max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"
          @text2process = File.read(file)

          lemmatized = @lemmatizer.process(@text2process, language: language, format: :text)
          File.write("#{@projectdir}/#{@filename}_lem.txt", lemmatized)
        end
      end

      # POS tagging for input
      def tagger(language)
        Dir.glob(@projectdir + '/*.*').reject do |file|
          file.end_with?('lem.txt')
        end.max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on POS #{file}"
          @text2process = File.read(file)

          # Get tagged tokens in different formats
          tagged_csv = @tagger.process(@text2process, language: language, format: :csv)
          tagged_xml = @tagger.process(@text2process, language: language, format: :xml)
          tagged_text = @tagger.process(@text2process, language: language)

          # Save in different formats
          File.open("#{@projectdir}/#{@filename}_pos.csv", 'w') do |f|
            tagged_csv.each { |row| f.puts(row.join(',')) }
          end
          File.write("#{@projectdir}/#{@filename}_pos.xml", tagged_xml)
          File.write("#{@projectdir}/#{@filename}_pos.txt", tagged_text.map do |t|
            "#{t[:text]}: pos:#{t[:pos]}, tag:#{t[:tag]}"
          end)
        end
      end

      # Named Entity Recognition for the input tokens
      def ner(language)
        Dir.glob(@projectdir + '/*.*').reject do |file|
          file.end_with?('lem.txt') || file.end_with?('pos.txt') || file.end_with?('pos.csv') || file.end_with?('pos.xml')
        end.max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on NER #{file}"
          @text2process = File.read(file)

          # Get entities in different formats
          entities_csv = @ner.process(@text2process, language: language, format: :csv)
          entities_xml = @ner.process(@text2process, language: language, format: :xml)
          entities_text = @ner.process(@text2process, language: language)

          # Save in different formats
          File.open("#{@projectdir}/#{@filename}_ner.csv", 'w') do |f|
            entities_csv.each { |row| f.puts(row.join(',')) }
          end
          File.write("#{@projectdir}/#{@filename}_ner.xml", entities_xml)
          File.write("#{@projectdir}/#{@filename}_ner.txt", entities_text.map { |e| "#{e[:text]}: label:#{e[:label]}" })
        end
      end
    end
  end
end
