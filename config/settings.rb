#!/usr/bin/env ruby

module RubyCrumbler
  module Config
    # Application settings
    APP_NAME = 'RubyCrumbler'
    APP_VERSION = '0.0.9'

    # Window settings
    WINDOW_WIDTH = 300
    WINDOW_HEIGHT = 800
    ABOUT_WINDOW_WIDTH = 700
    ABOUT_WINDOW_HEIGHT = 500
    DOCUMENTATION_WINDOW_WIDTH = 400
    DOCUMENTATION_WINDOW_HEIGHT = 600

    # File settings
    MAX_FILE_SIZE = 50 * 1024 * 1024 # 50MB in bytes
    SUPPORTED_FILE_TYPES = %w[.txt .xml .html]

    # Language settings
    SUPPORTED_LANGUAGES = {
      'EN' => 'en_core_web_lg',
      'DE' => 'de_core_news_lg'
    }

    # File naming conventions
    FILE_SUFFIXES = {
      clean: 'cl',
      normalize: 'n',
      normalize_lowercase: 'l',
      normalize_contractions: 'c',
      tokenize: 'tok',
      stopwords: 'nost',
      lemmatize: 'lem',
      pos_tag: 'pos',
      ner: 'ner'
    }

    # Output formats
    OUTPUT_FORMATS = {
      basic: ['txt'],
      advanced: %w[txt csv xml]
    }

    # Font settings
    FONTS = {
      default: {
        family: 'Helvetica',
        sizes: {
          small: 12,
          medium: 13,
          large: 14
        },
        weights: {
          normal: :normal,
          bold: :bold
        },
        styles: {
          normal: :normal,
          italic: :italic
        },
        stretches: {
          normal: :normal
        }
      }
    }

    # Repository information
    REPO_URL = 'https://github.com/joh-ga/RubyCrumbler'

    # Credits
    DEVELOPERS = [
      'Laura Bernardy',
      'Nora Dirlam',
      'Jakob Engel',
      'Johanna Garthe'
    ]

    # Feature descriptions
    FEATURE_DESCRIPTIONS = {
      data_cleaning: 'Removes redundant whitespaces, punctuation, special symbols, HTML tags, and URLs.',
      normalization: 'Removes punctuation symbols.',
      normalization_lowercase: 'Removes punctuation symbols and converts text to lowercase.',
      normalization_contractions: 'Removes punctuation symbols and expands contractions.',
      tokenization: 'Splits pre-processed data into individual tokens.',
      stopword_removal: 'Removes common words that carry little meaning.',
      lemmatization: 'Reduces words to their base form using POS classification.',
      pos_tagging: 'Identifies and labels parts of speech.',
      ner: 'Labels named entities such as persons, organizations, and places.'
    }
  end
end
