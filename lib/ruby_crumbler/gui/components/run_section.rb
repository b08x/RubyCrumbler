#!/usr/bin/env ruby

module RubyCrumbler
  module GUI
    module Components
      class RunSection
        include Glimmer
        include RubyCrumbler::Pipeline

        attr_reader :fincount, :progressbar, :label

        def initialize(input_section, processing_options)
          @input_section = input_section
          @processing_options = processing_options
          @fincount = 0
        end

        def create
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

        private

        def create_run_button
          button('Run') do
            stretchy false
            on_clicked do
              process_text
            end
          end
        end

        def create_progress_section
          label { stretchy false }
          @progressbar = progress_bar do
            stretchy false
          end
          @label = label do
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
          if @processing_options.clcbchecked
            @input_section.doc.cleaner.cleantext
            update_progress
          end

          process_normalization
        end

        def process_normalization
          if @processing_options.normchecked && !@processing_options.normlowchecked && !@processing_options.normcontchecked
            @input_section.doc.normalize(false, @input_section.lang, false)
            update_progress
          elsif (@processing_options.normchecked && @processing_options.normlowchecked && !@processing_options.normcontchecked) ||
                (@processing_options.normchecked && @processing_options.normcontchecked && !@processing_options.normlowchecked)
            @input_section.doc.normalize(@processing_options.normcontchecked, @input_section.lang,
                                         @processing_options.normlowchecked)
            update_progress(2)
          elsif @processing_options.normchecked && @processing_options.normlowchecked && @processing_options.normcontchecked
            @input_section.doc.normalize(@processing_options.normcontchecked, @input_section.lang,
                                         @processing_options.normlowchecked)
            update_progress(3)
          elsif !@processing_options.normchecked && @processing_options.normlowchecked && @processing_options.normcontchecked
            @processing_options.norm.checked = true
            @input_section.doc.normalize(@processing_options.normcontchecked, @input_section.lang,
                                         @processing_options.normlowchecked)
            @processing_options.count += 1
            update_progress(3)
          elsif (!@processing_options.normchecked && @processing_options.normlowchecked && !@processing_options.normcontchecked) ||
                (!@processing_options.normchecked && !@processing_options.normlowchecked && @processing_options.normcontchecked)
            @processing_options.norm.checked = true
            @input_section.doc.normalize(@processing_options.normcontchecked, @input_section.lang,
                                         @processing_options.normlowchecked)
            @processing_options.count += 1
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
          return unless @processing_options.tokchecked

          @input_section.doc.tokenizer(@input_section.lang)
          update_progress
        end

        def process_stopwords
          return unless @processing_options.srchecked

          if !@processing_options.tokchecked && !@processing_options.autotokchecked
            # @processing_options.enable_tokenization
            @input_section.doc.tokenizer(@input_section.lang)
            @processing_options.count += 1
            update_progress
          end
          @input_section.doc.stopwordsclean(@input_section.lang)
          update_progress
        end

        def process_lemmatization
          return unless @processing_options.lemchecked

          if !@processing_options.tokchecked && !@processing_options.autotokchecked
            # @processing_options.enable_tokenization
            @input_section.doc.tokenizer(@input_section.lang)
            @processing_options.count += 1
            update_progress
          end
          @input_section.doc.lemmatizer(@input_section.lang)
          update_progress
        end

        def process_pos_tagging
          return unless @processing_options.poschecked

          if !@processing_options.tokchecked && !@processing_options.autotokchecked
            # @processing_options.enable_tokenization
            @input_section.doc.tokenizer(@input_section.lang)
            @processing_options.count += 1
            update_progress
          end
          @input_section.doc.tagger(@input_section.lang)
          update_progress
        end

        def process_ner
          return unless @processing_options.nerchecked

          if !@processing_options.tokchecked && !@processing_options.autotokchecked
            # @processing_options.enable_tokenization
            @input_section.doc.tokenizer(@input_section.lang)
            @processing_options.count += 1
            update_progress
          end
          @input_section.doc.ner(@input_section.lang)
          update_progress
        end

        def update_progress(increment = 1)
          @fincount += increment
          progress = (@fincount * 100.0 / @processing_options.count).round
          progress = [progress, 100].min # Ensure progress never exceeds 100
          @progressbar.value = progress
          @label.text = 'Text processing finished!' if progress == 100
        end
      end
    end
  end
end
