#!/usr/bin/env ruby
require 'ruby-spacy'

module Crumbler
  module Pipeline
    class Ner
      def initialize
        @en = Spacy::Language.new('en_core_web_lg')
        @de = Spacy::Language.new('de_core_news_lg')
      end

      # Extract named entities from text
      def extract_entities(text, language: 'EN')
        doc = language == 'EN' ? @en.read(text) : @de.read(text)

        doc.ents.map do |entity|
          {
            text: entity.text,
            label: entity.label
          }
        end
      end

      # Export entities to different formats
      def export(entities, format: :hash)
        case format
        when :hash
          entities
        when :csv
          [%w[text label]] + entities.map { |e| [e[:text], e[:label]] }
        when :xml
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.root do
              entities.each do |entity|
                xml.tokens('token' => entity[:text]) do
                  xml.label entity[:label]
                end
              end
            end
          end
          builder.to_xml
        else
          raise ArgumentError, "Unsupported format: #{format}"
        end
      end

      # Process text by extracting entities and exporting in specified format
      def process(text, language: 'EN', format: :hash)
        entities = extract_entities(text, language: language)
        export(entities, format: format)
      end
    end
  end
end
