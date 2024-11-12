#!/usr/bin/env ruby

module RubyCrumbler
  module GUI
    class CrumblerGUI
      include Glimmer
      include RubyCrumbler::Pipeline

      def initialize
        @count = 0
        @fincount = 0
        ProgressBar.create
      end

      def launch
        create_menu_bar
        create_main_window
      end

      private

      def create_menu_bar
        menu('Help') do
          create_about_menu_item
          create_documentation_menu_item
        end
      end

      def create_about_menu_item
        menu_item('About') do
          on_clicked do
            window('About RubyCrumbler', 700, 500, false) do
              on_closing do
                window.destroy
                1
              end
              margined true
              vertical_box do
                area do
                  text do
                    default_font family: 'Helvetica', size: 13, weight: :normal, italic: :normal, stretch: :normal
                    string do
                      font family: 'Helvetica', size: 14, weight: :bold, italic: :normal, stretch: :normal
                      "RubyCrumbler Version #{RubyCrumbler::VERSION}\n\n"
                    end
                    string("Developed by Laura Bernardy, Nora Dirlam, Jakob Engel, and Johanna Garthe.\nMarch 31, 2022\n\nThis project is open source on GitHub.")
                  end
                end
                button('Go to GitHub Repository') do
                  stretchy true
                  on_clicked do
                    system('open', 'https://github.com/joh-ga/RubyCrumbler')
                  end
                end
              end
            end.show
          end
        end
      end

      def create_documentation_menu_item
        menu_item('Documentation') do
          on_clicked do
            window('Documentation', 400, 600, false) do
              on_closing do
                window.destroy
                1
              end
              margined true
              vertical_box do
                area do
                  text do
                    default_font family: 'Helvetica', size: 12, weight: :normal, italic: :normal, stretch: :normal
                    string do
                      font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
                      "Description of Features\n\n"
                    end
                    string("Please find below all the necessary information about the individual features.\n\n")
                    create_documentation_text
                  end
                end
                button('Go to GitHub Repository') do
                  stretchy false
                  on_clicked do
                    system('open', 'https://github.com/joh-ga/RubyCrumbler')
                  end
                end
              end
            end.show
          end
        end
      end

      def create_main_window
        window('RubyCrumbler', 300, 800) do
          margined(true)
          vertical_box do
            create_input_section
            horizontal_separator { stretchy false }
            create_run_section
          end
        end.show
      end

      def create_input_section
        horizontal_box do
          stretchy false
          vertical_box do
            create_language_selection
            create_upload_center
          end
          vertical_box do
            create_preprocessing_options
            create_nlp_options
          end
        end
      end

      def create_language_selection
        group('Language of Text Input') do
          stretchy false
          vertical_box do
            label("Please specify the language in which your input text data is written.\n" \
            "Note: This information is mandatory to run the program.\n") { stretchy false }

            combobox do
              stretchy false
              items 'English', 'German'
              selected 'English'
              @lang = 'EN'

              on_selected do |c|
                @lang = if c.selected_item == 'English'
                          'EN'
                        else
                          'DE'
                        end
              end
            end
            label
          end
        end
      end

      def create_upload_center
        group('Upload Center') do
          stretchy false
          vertical_box do
            label("Choose a file(s) or a directory, or specify a URL whose text content should be used to upload.\n" \
            "Note: Total file size may not exceed 50MB. File type must be TXT.\n") do
              stretchy false
            end
            create_file_upload_button
            create_directory_upload_button
            create_url_upload_section
          end
        end
      end

      def create_file_upload_button
        button('Upload from file(s)') do
          stretchy false
          on_clicked do
            file = open_file
            if file.nil?
              msg_box('ERROR: No File selected.')
            else
              @input = file
              @projectname = File.basename(@input, '.*')
              @doc = Features.new
              puts @input unless file.nil?
              @doc.newproject(@input, @projectname)
              msg_box('Notification', 'Upload successfully completed.')
            end
          end
        end
      end

      def create_directory_upload_button
        button('Upload file(s) from directory') do
          stretchy false
          on_clicked do
            dir = Tk.chooseDirectory
            @input = dir
            @projectname = File.basename(@input, '.*')
            @projectname = "#{@projectname}_process"
            if @projectname == '_process'
              msg_box('ERROR: No Folder selected.')
            else
              @doc = Features.new
              @doc.newproject(@input, @projectname)
              msg_box('Notification', 'Upload successfully completed.')
            end
          end
        end
      end

      def create_url_upload_section
        label("\nEnter URL:") { stretchy false }
        @entry = entry do
          stretchy false
          on_changed do
            @url = @entry.text
          end
        end
        button('Upload text from website') do
          stretchy false
          on_clicked do
            @input = @url
            if @input.nil?
              msg_box('ERROR: No URL selected.')
            else
              @projectname = File.basename(@input, '.*')
              @doc = Features.new
              puts @input unless @input.nil?
              @doc.newproject(@input, @projectname)
              msg_box('Notification', 'Upload successfully completed.')
            end
          end
        end
      end

      def create_preprocessing_options
        group('Pre-Processing') do
          stretchy false
          vertical_box do
            label("Select all or respective features.\n" \
            'Note: See the documentation for more information about each feature.') { stretchy false }

            @clcb = checkbox('Data cleaning') do
              stretchy false
              on_toggled do |_c|
                @clcbchecked = @clcb.checked?
                @count += 1 if @clcb.checked == true
              end
            end

            @norm = checkbox('Normalization') do
              stretchy false
              on_toggled do |_c|
                @normchecked = @norm.checked?
                @count += 1 if @norm.checked == true
              end
            end

            @normlow = checkbox('Normalization (lowercase)') do
              stretchy false
              on_toggled do |_c|
                @normlowchecked = @normlow.checked?
                @count += 1 if @normlow.checked == true
              end
            end

            @normcont = checkbox('Normalization (contractions)') do
              stretchy false
              on_toggled do |_c|
                @normcontchecked = @normcont.checked?
                @count += 1 if @normcont.checked == true
              end
            end
          end
        end
      end

      def create_nlp_options
        group('Natural Language Processing – Tasks') do
          stretchy false
          vertical_box do
            label("Select all or respective features.\n" \
            'Note: See the documentation for more information about each feature.') { stretchy false }

            @tok = checkbox('Tokenization') do
              stretchy false
              on_toggled do |_c|
                @tokchecked = @tok.checked?
                @count += 1 if @tok.checked? == true
              end
            end

            @sr = checkbox('Stopword removal') do
              stretchy false
              on_toggled do |_c|
                @srchecked = @sr.checked?
                @count += 1 if @sr.checked == true
              end
            end

            @lem = checkbox('Lemmatization') do
              stretchy false
              on_toggled do |_c|
                @lemchecked = @lem.checked?
                @count += 1 if @lem.checked == true
              end
            end

            @pos = checkbox('Part-of-Speech Tagging') do
              stretchy false
              on_toggled do |_c|
                @poschecked = @pos.checked?
                @count += 1 if @pos.checked == true
              end
            end

            @ner = checkbox('Named Entity Recognition') do
              stretchy false
              on_toggled do |_c|
                @nerchecked = @ner.checked?
                @count += 1 if @ner.checked == true
              end
            end
          end
        end
      end

      def create_run_section
        horizontal_box do
          stretchy false
          group do
            vertical_box do
              create_run_button
              create_progress_section
              create_new_project_button
            end
          end
        end
      end

      def create_run_button
        button('Run') do
          stretchy false
          on_clicked do
            process_text
          end
        end
      end

      def create_progress_section
        label('Status – Progress bar') { stretchy false }
        @progressbar = progress_bar do
          stretchy false
        end
        @label = label('') do
          stretchy false
        end
      end

      def create_new_project_button
        button('New Project') do
          stretchy false
          on_clicked do
            window.destroy
            Kernel.exec('ruby rubycrumbler_maclinux.rb')
          end
        end
      end

      def process_text
        process_preprocessing
        process_nlp
      end

      def process_preprocessing
        if @clcbchecked
          @doc.cleantext
          update_progress
        end

        process_normalization
      end

      def process_normalization
        if @normchecked && !@normlowchecked && !@normcontchecked
          @doc.normalize(false, @lang, false)
          update_progress
        elsif (@normchecked && @normlowchecked && !@normcontchecked) || (@normchecked && @normcontchecked && !@normlowchecked)
          @doc.normalize(@normcontchecked, @lang, @normlowchecked)
          update_progress(2)
        elsif @normchecked && @normlowchecked && @normcontchecked
          @doc.normalize(@normcontchecked, @lang, @normlowchecked)
          update_progress(3)
        elsif !@normchecked && @normlowchecked && @normcontchecked
          @norm.checked = true
          @doc.normalize(@normcontchecked, @lang, @normlowchecked)
          @count += 1
          update_progress(3)
        elsif (!@normchecked && @normlowchecked && !@normcontchecked) || (!@normchecked && !@normlowchecked && @normcontchecked)
          @norm.checked = true
          @doc.normalize(@normcontchecked, @lang, @normlowchecked)
          @count += 1
          update_progress(2)
        end
      end

      def process_nlp
        process_tokenization
        process_stopwords
        process_lemmatization
        process_pos_tagging
        process_ner
      end

      def process_tokenization
        return unless @tokchecked

        @doc.tokenizer(@lang)
        update_progress
      end

      def process_stopwords
        return unless @srchecked

        if !@tokchecked && !@autotokchecked
          @autotokchecked = (@tok.checked = true)
          @doc.tokenizer(@lang)
          @count += 1
          update_progress
        end
        @doc.stopwordsclean(@lang)
        update_progress
      end

      def process_lemmatization
        return unless @lemchecked

        if !@tokchecked && !@autotokchecked
          @autotokchecked = (@tok.checked = true)
          @doc.tokenizer(@lang)
          @count += 1
          update_progress
        end
        @doc.lemmatizer(@lang)
        update_progress
      end

      def process_pos_tagging
        return unless @poschecked

        if !@tokchecked && !@autotokchecked
          @autotokchecked = (@tok.checked = true)
          @doc.tokenizer(@lang)
          @count += 1
          update_progress
        end
        @doc.tagger(@lang)
        update_progress
      end

      def process_ner
        return unless @nerchecked

        if !@tokchecked && !@autotokchecked
          @autotokchecked = (@tok.checked = true)
          @doc.tokenizer(@lang)
          @count += 1
          update_progress
        end
        @doc.ner(@lang)
        update_progress
      end

      def update_progress(increment = 1)
        @fincount += increment
        progress = (@fincount * 100.0 / @count).round
        progress = [progress, 100].min # Ensure progress never exceeds 100
        @progressbar.value = progress
        @label.text = 'Text processing finished!' if progress == 100
      end

      def create_documentation_text
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          underline :single
          "Pre-Processing\n"
        end
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Data cleaning: '
        end
        string("This includes removing redundant whitespaces, punctuation (redundant dots), special symbols (e.g., line break, new line), hash tags, HTML tags, and URLs.\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Normalization: '
        end
        string("This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark).\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Normalization (lowercase): '
        end
        string("This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting the text into lowercase.\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Normalization (contractions): '
        end
        string("This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting contractions)\n\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          underline :single
          "Natural Language Processings – Tasks \n"
        end
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Tokenization: '
        end
        string("This includes splitting the pre-processed data into individual characters or tokens.\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Stopword removal: '
        end
        string("Stopwords are words that do not carry much meaning but are important grammatically as\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Lemmatization: '
        end
        string("This includes reduction of a word to its semantic base form according to POS classification. Examples: computing - compute, sung - sing, obviously - obviously.\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Part-of-Speech Tagging: '
        end
        string("This includes identifying and labeling the parts of speech of text data.\n")
        string do
          font family: 'Helvetica', size: 12, weight: :bold, italic: :normal, stretch: :normal
          'Named Entity Recognition: '
        end
        string("This includes labeling the so-called named entities\n\n\n")
        string do
          font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
          "Information about the File Naming Convention\n\n"
        end
        string("To enable a quick identification and location of your converted document depending on the feature applied, the following file naming convention is used in RubyCrumbler.\n\n\n")
        string do
          font family: 'Helvetica', size: 13, weight: :bold, italic: :normal, stretch: :normal
          "Notes\n\n"
        end
        string('More information and the source code are available on GitHub.')
      end
    end
  end
end
