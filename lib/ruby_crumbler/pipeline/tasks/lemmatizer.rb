#!/usr/bin/env ruby
require 'ruby-spacy'

module RubyCrumbler
  module Pipeline
    class Lemmatizer
      def initialize
        @en = Spacy::Language.new('en_core_web_lg')
        @de = Spacy::Language.new('de_core_news_lg')
      end

      # Lemmatize text and return array of token-lemma pairs
      def lemmatize(text, language: 'EN')
        doc = language == 'EN' ? @en.read(text) : @de.read(text)

        doc.map do |token|
          {
            text: token.text,
            lemma: token.lemma
          }
        end
      end

      # Export lemmatized tokens to different formats
      def export(lemmatized_tokens, format: :hash)
        case format
        when :hash
          lemmatized_tokens
        when :text
          lemmatized_tokens.map { |t| "#{t[:text]}: lemma:#{t[:lemma]}" }
        when :table
          [%w[text lemma]] + lemmatized_tokens.map { |t| [t[:text], t[:lemma]] }
        else
          raise ArgumentError, "Unsupported format: #{format}"
        end
      end

      # Process text by lemmatizing and exporting in specified format
      def process(text, language: 'EN', format: :hash)
        lemmatized = lemmatize(text, language: language)
        export(lemmatized, format: format)
      end
    end
  end
end
