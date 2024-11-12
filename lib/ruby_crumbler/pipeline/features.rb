#!/usr/bin/env ruby

module RubyCrumbler
  module Pipeline
    class Features
      # initialize globally used variables
      def initialize
        @en = Spacy::Language.new('en_core_web_lg')
        @de = Spacy::Language.new('de_core_news_lg')
      end

      # multidir function is automatically called, if a folder is used for input. For each file in the directory the chosen functions will be applied.
      def multidir(directory)
        directory = @projectdir
        @filenumber = Dir.glob(File.join(directory, '**', '*')).select { |file| File.file?(file) }.count
        # filenumber is later important for opening the x recent files in the methods
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
      # you can use txt, xml or html files
      # created folder is called by project name (= name of origin directory or file)
      # the copied files will keep their names and are txts
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

      # clean raw text file from project folder from code, markup, special symbols (latin characters (if English), currency symbols, emojis etc.), urls, digits and additional spaces
      # output is a txt file with additional _cl for "cleaned" in name
      # the file.open line is universal for using the latest (last processed) file in directory
      def cleantext
        Dir.foreach(@projectdir) do |filename|
          next if ['.', '..'].include?(filename)

          puts "working on #{filename}"
          @filename = File.basename(filename, '.*')
          @text2process = File.open(Dir.glob(@projectdir + "/#{@filename}.*").max_by { |f| File.mtime(f) }, 'r')
          @text2process = File.read(@text2process)
          @text2process = @text2process.gsub('\n', '').gsub('\r', '').gsub(/\\u[a-f0-9]{4}/i, '').gsub(%r{https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,}}, '').gsub(/\d/, '').gsub(/[^\w\s.'´`äÄöÖüÜß]/, '').gsub(/\.{2,}/, ' ').gsub(
            / {2,}/, ' '
          )
          File.write("#{@projectdir}/#{@filename}_cl.txt", @text2process)
          p @text2process
        end
      end

      # normalize text (from cleaned text file or raw text file) by choosing lowercasing and/or separating contractions (both optional)
      def normalize(contractions = false, language = 'EN', low = false)
        Dir.glob(@projectdir + '/*.*').max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"
          @file2process = file
          @text2process = File.open(@file2process)
          @text2process = File.read(@text2process)
          @text2process = @text2process.gsub('.', '').gsub(',', '').gsub('!', '').gsub('?', '').gsub(':', '').gsub(';', '').gsub('(', '').gsub(')', '').gsub('[', '').gsub(']', '').gsub('"', '').gsub('„', '').gsub('»', '').gsub('«', '').gsub('›', '').gsub('‹', '').gsub(
            '–', ''
          )
          puts @text2process
          lc = ''
          cons = ''
          if low == true
            lc = 'l'
            @text2process = @text2process.downcase
          end
          if contractions == true
            cons = 'c'
            contractions(language)
          end
          File.write("#{@projectdir}/#{@filename}_n#{lc}#{cons}.txt", @text2process)
          p @text2process
        end
      end

      # tokenize the input text (with spaCy) and show number of tokens
      def tokenizer(language)
        Dir.glob(@projectdir + '/*.*').max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"
          @file2process = file
          @text2process = File.open(@file2process)
          @text2process = File.read(@text2process)

          # tokenization
          doc = if language == 'EN'
                  @en.read(@text2process)
                else
                  @de.read(@text2process)
                end
          row = []
          count = 0
          doc.each do |token|
            count += 1
            row << token.text
          end

          # write tokenized content into new output file
          File.open("#{@projectdir}/#{@filename}_tok.txt", 'w') do |f|
            f.write(row)
            puts("Total number of tokens: #{count}")
          end
        end
      end

      # clean input from stopwords (provided by spaCy)
      def stopwordsclean(language)
        Dir.glob(@projectdir + '/*.*').max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"
          @file2process = file
          @text2process = File.open(@file2process)
          @text2process = File.read(@text2process)
          @text2process = Kernel.eval(@text2process)
          stopwords = if language == 'EN'
                        @en.Defaults.stop_words.to_s.gsub("'", '"').delete('{}" ').gsub(', "' + ").split(',')
                      else
                        @de.Defaults.stop_words.to_s.gsub(" + '", ' + "').delete('{}" + ').gsub(', "'").split(',')
                      end
          shared = @text2process & stopwords
          textosw = @text2process - shared
          File.write("#{@projectdir}/#{@filename}_nost.txt", textosw)
        end
      end

      # convert input tokens to their respective lemma (based on spaCy)
      def lemmatizer(language)
        Dir.glob(@projectdir + '/*.*').max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on #{@filename}"
          @file2process = file
          @text2process = File.open(@file2process)
          @text2process = File.read(@text2process)
          @text2process = Kernel.eval(@text2process)
          @text2process = @text2process.join(', ').gsub(',', '')

          # lemmatization
          doc = if language == 'EN'
                  @en.read(@text2process)
                else
                  @de.read(@text2process)
                end
          rows = []
          output = []
          headings = %w[text lemma]

          doc.each do |token|
            rows << [token.text, token.lemma]
            output.append(token.text + ': lemma:' + token.lemma)
          end

          # output in terminal
          table = Terminal::Table.new rows: rows, headings: headings
          puts table
          # save to txt
          File.write("#{@projectdir}/#{@filename}_lem.txt", output)
        end
      end

      # POS tagging for input based on spaCy POS
      def tagger(language)
        Dir.glob(@projectdir + '/*.*').reject do |file|
          file.end_with?('lem.txt')
        end.max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on POS #{file}"
          @file2process = file
          @text2process = File.open(@file2process)
          @text2process = File.read(@text2process)
          @text2process = Kernel.eval(@text2process)
          @text2process = @text2process.join(' ').gsub(',', '')
          doc = if language == 'EN'
                  @en.read(@text2process)
                else
                  @de.read(@text2process)
                end
          builder = Nokogiri::XML::Builder.new
          headings = [%w[text pos tag]]
          @rows = []
          output = []

          doc.each do |token|
            @rows << [token.text, token.pos, token.tag]
            output.append(token.text + ': pos:' + token.pos + ', tag:' + token.tag)
          end
          p @rows

          # save to csv
          File.open("#{@projectdir}/#{@filename}_pos.csv", 'w') do |f|
            f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(''))
            f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(''))
          end
          # save to txt
          File.write("#{@projectdir}/#{@filename}_pos.txt", output)
          # save to xml
          builder.new do |xml|
            xml.root do
              for r in @rows
                xml.tokens('token' => (r[0])) do
                  xml.pos r[1]
                  xml.tag r[2]
                end
              end
            end
          end
          pos_xml = builder.to_xml
          File.write("#{@projectdir}/#{@filename}_pos.xml", pos_xml)
        end
      end

      # Named Entity Recognition for the input tokens
      def ner(language)
        Dir.glob(@projectdir + '/*.*').reject do |file|
          file.end_with?('lem.txt') || file.end_with?('pos.txt') || file.end_with?('pos.csv') || file.end_with?('pos.xml')
        end.max_by(@filenumber) { |f| File.mtime(f) }.each do |file|
          @filename = File.basename(file, '.*')
          puts "working on NER #{file}"
          @file2process = file
          @text2process = File.open(@file2process)
          @text2process = File.read(@text2process)
          @text2process = @text2process
          @text2process = Kernel.eval(@text2process).join(' ')
          doc = if language == 'EN'
                  @en.read(@text2process)
                else
                  @de.read(@text2process)
                end
          builder = Nokogiri::XML::Builder.new

          headings = [%w[text label]]
          @rows = []
          output = []

          doc.ents.each do |ent|
            @rows << [ent.text, ent.label]
            output.append(ent.text + ': label:' + ent.label)
          end

          # save to csv
          File.open("#{@projectdir}/#{@filename}_ner.csv", 'w') do |f|
            f.write(headings.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(''))
            f.write(@rows.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join(''))
          end
          # save to txt
          File.write("#{@projectdir}/#{@filename}_ner.txt", output)
          # save to xml
          builder.new do |xml|
            xml.root do
              for r in @rows
                xml.tokens('token' => (r[0])) do
                  xml.label r[1]
                end
              end
            end
          end
          ner_xml = builder.to_xml
          File.write("#{@projectdir}/#{@filename}_ner.xml", ner_xml)
        end
      end

      private

      def contractions(language)
        # contractions of English language
        @contractions_en = {
          "ain't" => 'are not',
          "aren't" => 'are not',
          "Ain't" => 'Are not',
          "Aren't" => 'Are not',
          "Can't" => 'Cannot',
          "Can't've" => 'Cannot have',
          "'Cause" => 'Because',
          "Could've" => 'Could have',
          "Couldn't" => 'Could not',
          "Couldn't've" => 'could not have',
          "can't" => 'cannot',
          "can't've" => 'cannot have',
          "'cause" => 'because',
          "could've" => 'could have',
          "couldn't" => 'could not',
          "couldn't've" => 'could not have',
          "didn't" => 'did not',
          "doesn't" => 'does not',
          "don't" => 'do not',
          "Didn't" => 'Did not',
          "Doesn't" => 'does not',
          "Don't" => 'Do not',
          "hadn't" => 'had not',
          "hadn't've" => 'had not have',
          "hasn't" => 'has not',
          "haven't" => 'have not',
          "he'd" => 'he would',
          "he'd've" => 'he would have',
          "he'll" => 'he will',
          "he'll've" => 'he will have',
          "he's" => 'he is',
          "how'd" => 'how did',
          "how'd'y" => 'how do you',
          "how'll" => 'how will',
          "how's" => 'how is',
          "Hadn't" => 'had not',
          "Hadn't've" => 'had not have',
          "Hasn't" => 'has not',
          "Haven't" => 'have not',
          "He'd" => 'He would',
          "He'd've" => 'He would have',
          "He'll" => 'He will',
          "He'll've" => 'He will have',
          "He's" => 'He is',
          "How'd" => 'How did',
          "How'd'y" => 'How do you',
          "How'll" => 'How will',
          "How's" => 'How is',
          "I'd" => 'I would',
          "I'd've" => 'I would have',
          "I'll" => 'I will',
          "I'll've" => 'I will have',
          "I'm" => 'I am',
          "I've" => 'I have',
          "i'd" => 'i would',
          "i'd've" => 'i would have',
          "i'll" => 'i will',
          "i'll've" => 'i will have',
          "i'm" => 'i am',
          "i've" => 'i have',
          "it's" => 'it is',
          "isn't" => 'is not',
          "it'd" => 'it would',
          "it'd've" => 'it would have',
          "it'll" => 'it will',
          "it'll've" => 'it will have',
          "It's" => 'It is',
          "Isn't" => 'Is not',
          "It'd" => 'It would',
          "It'd've" => 'It would have',
          "It'll" => 'It will',
          "It'll've" => 'It will have',
          "let's" => 'let us',
          "Let's" => 'Let us',
          "ma'am" => 'madam',
          "mayn't" => 'may not',
          "might've" => 'might have',
          "mightn't" => 'might not',
          "mightn't've" => 'might not have',
          "must've" => 'must have',
          "mustn't" => 'must not',
          "mustn't've" => 'must not have',
          "Ma'am" => 'Madam',
          "Mayn't" => 'May not',
          "Might've" => 'Might have',
          "Mightn't" => 'Might not',
          "Mightn't've" => 'Might not have',
          "Must've" => 'Must have',
          "Mustn't" => 'Must not',
          "Mustn't've" => 'Must not have',
          "needn't" => 'need not',
          "needn't've" => 'need not have',
          "Needn't" => 'Need not',
          "Needn't've" => 'Need not have',
          "o'clock" => 'of the clock',
          "oughtn't" => 'ought not',
          "oughtn't've" => 'ought not have',
          "O'clock" => 'Of the clock',
          "Oughtn't" => 'Ought not',
          "Oughtn't've" => 'Ought not have',
          "shan't" => 'shall not',
          "sha'n't" => 'shall not',
          "shan't've" => 'shall not have',
          "she'd" => 'he would',
          "she'd've" => 'she would have',
          "she'll" => 'she will',
          "she'll've" => 'she will have',
          "she's" => 'she is',
          "should've" => 'should have',
          "shouldn't" => 'should not',
          "shouldn't've" => 'should not have',
          "so've" => 'so have',
          "so's" => 'so is',
          "Shan't" => 'Shall not',
          "Sha'n't" => 'Shall not',
          "Shan't've" => 'Shall not have',
          "She'd" => 'She would',
          "She'd've" => 'She would have',
          "She'll" => 'She will',
          "She'll've" => 'She will have',
          "She's" => 'She is',
          "Should've" => 'Should have',
          "Shouldn't" => 'Should not',
          "Shouldn't've" => 'Should not have',
          "So've" => 'So have',
          "So's" => 'So is',
          "that'd" => 'that would',
          "that'd've" => 'that would have',
          "that's" => 'that is',
          "there'd" => 'there would',
          "there'd've" => 'there would have',
          "there's" => 'there is',
          "they'd" => 'they would',
          "they'd've" => 'they would have',
          "they'll" => 'they will',
          "they'll've" => 'they will have',
          "they're" => 'they are',
          "they've" => 'they have',
          "to've" => 'to have',
          "That'd" => 'That would',
          "That'd've" => 'that would have',
          "That's" => 'That is',
          "There'd" => 'There would',
          "There'd've" => 'There would have',
          "There's" => 'There is',
          "They'd" => 'They would',
          "They'd've" => 'they would have',
          "They'll" => 'They will',
          "They'll've" => 'They will have',
          "They're" => 'They are',
          "They've" => 'They have',
          "To've" => 'To have',
          "wasn't" => 'was not',
          "we'd" => 'we would',
          "we'd've" => 'we would have',
          "we'll" => 'we will',
          "we'll've" => 'we will have',
          "we're" => 'we are',
          "we've" => 'we have',
          "weren't" => 'were not',
          "what'll" => 'what will',
          "what'll've" => 'what will have',
          "what're" => 'what are',
          "what's" => 'what is',
          "what've" => 'what have',
          "when's" => 'when is',
          "when've" => 'when have',
          "where'd" => 'where did',
          "where's" => 'where is',
          "where've" => 'where have',
          "who'll" => 'who will',
          "who'll've" => 'who will have',
          "who's" => 'who is',
          "who've" => 'who have',
          "why's" => 'why is',
          "why've" => 'why have',
          "will've" => 'will have',
          "won't" => 'will not',
          "won't've" => 'will not have',
          "would've" => 'would have',
          "wouldn't" => 'would not',
          "wouldn't've" => 'would not have',
          "Wasn't" => 'Was not',
          "We'd" => 'We would',
          "We'd've" => 'We would have',
          "We'll" => 'We will',
          "We'll've" => 'We will have',
          "We're" => 'We are',
          "We've" => 'We have',
          "Weren't" => 'Were not',
          "What'll" => 'What will',
          "What'll've" => 'What will have',
          "What're" => 'What are',
          "What's" => 'What is',
          "What've" => 'What have',
          "When's" => 'When is',
          "When've" => 'When have',
          "Where'd" => 'Where did',
          "Where's" => 'Where is',
          "Where've" => 'Where have',
          "Who'll" => 'Who will',
          "Who'll've" => 'Who will have',
          "Who's" => 'Who is',
          "Who've" => 'Who have',
          "Why's" => 'Why is',
          "Why've" => 'Why have',
          "Will've" => 'Will have',
          "Won't" => 'Will not',
          "Won't've" => 'Will not have',
          "Would've" => 'Would have',
          "Wouldn't" => 'Would not',
          "Wouldn't've" => 'Would not have',
          "y'all" => 'you all',
          "y'all'd" => 'you all would',
          "y'all'd've" => 'you all would have',
          "y'all're" => 'you all are',
          "y'all've" => 'you all have',
          "you'd" => 'you would',
          "you'd've" => 'you would have',
          "you'll" => 'you will',
          "you'll've" => 'you will have',
          "you're" => 'you are',
          "you've" => 'you have',
          "Y'all" => 'You all',
          "Y'all'd" => 'You all would',
          "Y'all'd've" => 'You all would have',
          "Y'all're" => 'You all are',
          "Y'all've" => 'You all have',
          "You'd" => 'You would',
          "You'd've" => 'You would have',
          "You'll" => 'You will',
          "You'll've" => 'You will have',
          "You're" => 'You are',
          "You've" => 'You have'
        }

        # contractions of German language
        @contractions_de = {
          # preposition + article contractions
          'ans' => 'an das',
          "an's" => 'an das',
          'aufm' => 'auf dem',
          "auf'm" => 'auf dem',
          'aufn' => 'auf den',
          "auf'n" => 'auf den',
          'aufs' => 'auf das',
          "auf's" => 'auf das',
          'ausm' => 'aus dem',
          "aus'm" => 'aus dem',
          'außerm' => 'außer dem',
          "außer'm" => 'außer dem',
          'außers' => 'außer das',
          "außer's" => 'außer das',
          'durchn' => 'durch den',
          "durch'n" => 'durch den',
          'durchs' => 'durch das',
          "durch's" => 'durch das',
          'fürn' => 'für den',
          "für'n" => 'für den',
          'fürs' => 'für das',
          "für's" => 'für das',
          'gegens' => ' gegen das ',
          "gegen's" => 'gegen das',
          'nebens' => 'neben das',
          "neben's" => 'neben das',
          'hinterm' => 'hinter dem',
          "hinter'm" => 'hinter dem',
          'hintern' => 'hinter den',
          "hinter'n" => 'hinter den',
          'hinters' => 'hinter das',
          "hinter's" => 'hinter das',
          'ins' => 'in das',
          "in's" => 'in das',
          'mitm' => 'mit dem',
          "mit'm" => 'mit dem',
          'nachm' => 'nach dem',
          "nach'm" => 'nach dem',
          'ne' => 'eine',
          "'ne" => 'eine',
          'nen' => 'einen',
          "'nen" => 'einen',
          'ums' => 'um das',
          "um's" => 'um das',
          "um'n" => 'um einen',
          'umn' => 'um einen',
          'unterm' => 'unter dem',
          "unter'm" => 'unter dem',
          'untern' => 'unter den',
          "unter'n" => 'unter den',
          'unters' => 'unter das',
          "unter's" => 'unter das',
          'überm' => 'über dem',
          "über'm" => 'über dem',
          'übern' => 'über den',
          "über'n" => 'über den',
          'übers' => 'über das',
          "über's" => 'über das',
          'so n' => 'so ein',
          "so'n" => 'so ein',
          'so ne' => 'so eine',
          "so 'ne " => 'so eine',
          'vorm' => 'vor dem',
          "vor'm" => 'vor dem',
          "vor'n" => 'vor den',
          'vors' => 'vor das',
          "vor's" => 'vor das',
          'zwischens' => 'zwischen das',
          "zwischen's" => 'zwischen das',

          # verbal contractions + dummy subject "es" contractions
          "darf's" => 'darf es',
          'drüber' => 'darüber',
          'drunter' => 'darunter',
          "dürft's" => 'dürft es',
          "geht's" => 'geht es',
          "gib's" => 'gib es',
          "gibt's" => 'gibt es',
          "ging's" => 'ging es',
          "hab's" => 'habe es',
          "hat's" => 'hat es',
          "lass'" => 'lasse',
          "mach'" => 'mache',
          "mach's" => 'mach es',
          "macht's" => 'macht es',
          "schreib's" => 'schreibt es',
          "schreibt's" => 'schreibt es',
          "steht's" => 'steht es',
          "tu's" => 'tu es',
          "tut's" => 'tut es',
          "will's" => 'will es',
          "wollen's" => 'wollen es',
          "wollten's" => 'wollten es',
          "wollt's" => 'wollt es'
        }

        @text2process = @text2process.gsub(', ')
        if language == 'EN'
          @contractions_en.each { |k, v| @text2process = @text2process.gsub k, v }
        else
          @contractions_de.each { |k, v| @text2process = @text2process.gsub(/(?<=^|\W)#{k}(?=$|\W)/, v) }
        end
      end
    end
  end
end
