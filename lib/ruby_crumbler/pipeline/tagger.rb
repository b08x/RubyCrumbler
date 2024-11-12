#!/usr/bin/env ruby
require 'ruby-spacy'

module RubyCrumbler
  module Pipeline
    class Tagger
      def initialize
        @en = Spacy::Language.new('en_core_web_lg')
        @de = Spacy::Language.new('de_core_news_lg')
      end

      # Tag tokens with part-of-speech information
      def tag(text, language: 'EN')
        doc = language == 'EN' ? @en.read(text) : @de.read(text)

        doc.map do |token|
          {
            text: token.text,
            pos: token.pos,
            tag: token.tag
          }
        end
      end

      # Export tagged tokens to different formats
      def export(tagged_tokens, format: :hash)
        case format
        when :hash
          tagged_tokens
        when :csv
          [%w[text pos tag]] + tagged_tokens.map { |t| [t[:text], t[:pos], t[:tag]] }
        when :xml
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.root do
              tagged_tokens.each do |token|
                xml.tokens('token' => token[:text]) do
                  xml.pos token[:pos]
                  xml.tag token[:tag]
                end
              end
            end
          end
          builder.to_xml
        else
          raise ArgumentError, "Unsupported format: #{format}"
        end
      end

      # Process text by tagging and exporting in specified format
      def process(text, language: 'EN', format: :hash)
        tagged = tag(text, language: language)
        export(tagged, format: format)
      end
    end
  end
end
