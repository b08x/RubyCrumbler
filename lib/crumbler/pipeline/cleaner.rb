#!/usr/bin/env ruby

module Crumbler
  module Pipeline
    class Cleaner
      def initialize
        # No initialization needed for now
      end

      # Clean raw text from code, markup, special symbols, urls, digits and additional spaces
      def clean(text)
        text.gsub('\n', '')
            .gsub('\r', '')
            .gsub(/\\u[a-f0-9]{4}/i, '')
            .gsub(%r{https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,}}, '')
            .gsub(/\d/, '')
            .gsub(/[^\w\s.'´`äÄöÖüÜß]/, '')
            .gsub(/\.{2,}/, ' ')
            .gsub(/ {2,}/, ' ')
      end

      # Normalize text with optional contractions handling and lowercasing
      def normalize(text, contractions: false, language: 'EN', lowercase: false)
        text = text.gsub('.', '')
                   .gsub(',', '')
                   .gsub('!', '')
                   .gsub('?', '')
                   .gsub(':', '')
                   .gsub(';', '')
                   .gsub('(', '')
                   .gsub(')', '')
                   .gsub('[', '')
                   .gsub(']', '')
                   .gsub('"', '')
                   .gsub('„', '')
                   .gsub('»', '')
                   .gsub('«', '')
                   .gsub('›', '')
                   .gsub('‹', '')
                   .gsub('–', '')

        # Handle contractions based on language if enabled
        if contractions
          text = if language == 'EN'
                   text.gsub(/n't\b/, ' not')
                       .gsub(/'re\b/, ' are')
                       .gsub(/'m\b/, ' am')
                       .gsub(/'ll\b/, ' will')
                       .gsub(/'ve\b/, ' have')
                       .gsub(/'d\b/, ' would')
                       .gsub(/'s\b/, ' is')
                 else # DE
                   text.gsub(/(\w)'(\w)/, '\1\2') # Remove apostrophes between letters
                 end
        end

        lowercase ? text.downcase : text
      end

      # Convenience method to both clean and normalize text
      def process(text, contractions: false, language: 'EN', lowercase: false)
        normalized = normalize(clean(text), contractions: contractions, language: language, lowercase: lowercase)
        normalized.strip
      end
    end
  end
end
