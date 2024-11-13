#!/usr/bin/env ruby

require 'pragmatic_tokenizer'

module Crumbler
  module Pipeline
    class Tokenizer
      def initialize
        @tokenizer_options = {
          expand_contractions: true,
          remove_stop_words: false,
          downcase: false,
          punctuation: :none,
          numbers: :none,
          clean: true
        }
      end

      # Tokenize input text and return array of tokens
      def tokenize(text, language: 'EN')
        lang = language == 'EN' ? :en : :de
        tokenizer = PragmaticTokenizer::Tokenizer.new(
          @tokenizer_options.merge(language: lang)
        )
        tokenizer.tokenize(text)
      end

      # Remove stopwords from tokenized text
      def remove_stopwords(tokens, language: 'EN')
        lang = language == 'EN' ? :en : :de
        tokenizer = PragmaticTokenizer::Tokenizer.new(
          @tokenizer_options.merge(
            language: lang,
            remove_stop_words: true
          )
        )
        # We need to rejoin tokens and retokenize to use PragmaticTokenizer's
        # built-in stopword removal
        tokenizer.tokenize(tokens.join(' '))
      end

      # Process text by tokenizing and optionally removing stopwords
      def process(text, language: 'EN', remove_stopwords: false)
        tokens = tokenize(text, language: language)
        remove_stopwords ? remove_stopwords(tokens, language: language) : tokens
      end
    end
  end
end
