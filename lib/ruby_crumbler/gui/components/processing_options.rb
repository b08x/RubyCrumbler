#!/usr/bin/env ruby

module RubyCrumbler
  module GUI
    module Components
      class ProcessingOptions
        include Glimmer

        attr_accessor :count, :clcbchecked, :normchecked, :normlowchecked, :normcontchecked,
                      :tokchecked, :srchecked, :lemchecked, :poschecked, :nerchecked,
                      :autotokchecked, :norm, :tok

        def initialize
          @count = 0
          @clcbchecked = false
          @normchecked = false
          @normlowchecked = false
          @normcontchecked = false
          @tokchecked = false
          @srchecked = false
          @lemchecked = false
          @poschecked = false
          @nerchecked = false
          @autotokchecked = false
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
                  self.count += 1 if @clcb.checked?
                end
              end

              @norm = checkbox('Normalization') do
                stretchy false
                on_toggled do |_c|
                  @normchecked = @norm.checked?
                  self.count += 1 if @norm.checked?
                end
              end

              @normlow = checkbox('Normalization (lowercase)') do
                stretchy false
                on_toggled do |_c|
                  @normlowchecked = @normlow.checked?
                  self.count += 1 if @normlow.checked?
                end
              end

              @normcont = checkbox('Normalization (contractions)') do
                stretchy false
                on_toggled do |_c|
                  @normcontchecked = @normcont.checked?
                  self.count += 1 if @normcont.checked?
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
                  self.count += 1 if @tok.checked?
                end
              end

              @sr = checkbox('Stopword removal') do
                stretchy false
                on_toggled do |_c|
                  @srchecked = @sr.checked?
                  self.count += 1 if @sr.checked?
                end
              end

              @lem = checkbox('Lemmatization') do
                stretchy false
                on_toggled do |_c|
                  @lemchecked = @lem.checked?
                  self.count += 1 if @lem.checked?
                end
              end

              @pos = checkbox('Part-of-Speech Tagging') do
                stretchy false
                on_toggled do |_c|
                  @poschecked = @pos.checked?
                  self.count += 1 if @pos.checked?
                end
              end

              @ner = checkbox('Named Entity Recognition') do
                stretchy false
                on_toggled do |_c|
                  @nerchecked = @ner.checked?
                  self.count += 1 if @ner.checked?
                end
              end
            end
          end
        end

        def enable_tokenization
          @autotokchecked = true
          @tok.checked = true if @tok
        end
      end
    end
  end
end
