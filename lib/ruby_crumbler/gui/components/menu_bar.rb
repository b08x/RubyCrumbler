#!/usr/bin/env ruby

module RubyCrumbler
  module GUI
    module Components
      class MenuBar
        include Glimmer

        def create
          menu('Help') do
            create_about_menu_item
            create_documentation_menu_item
          end
        end

        private

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
end
