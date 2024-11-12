#!/usr/bin/env ruby

module RubyCrumbler
  module GUI
    module Components
      class ProcessingOptions
        include Glimmer

        attr_reader :count, :clcbchecked, :normchecked, :normlowchecked, :normcontchecked,
                    :tokchecked, :srchecked, :lemchecked, :poschecked, :nerchecked,
                    :autotokchecked, :norm, :tok

        def initialize
          @count = 0
        end

        def create(container)
          container.vertical_box do
            create_preprocessing_group
            create_nlp_group
          end
        end

        private

        def create_preprocessing_group
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

        def create_nlp_group
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

        # def enable_tokenization
        #   @autotokchecked = (@tok.checked = true)
        # end
      end
    end
  end
end
