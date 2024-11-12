# RubyCrumbler

Ready to crumble your text for common NLP tasks? This repository is home of RubyCrumbler, a simple script to download, that provides a GUI desktop application written in Ruby to apply common Natural Language Processing (NLP) tasks on your English or German text files.

The script may also run with older Ruby versions. It was sucessfully tested with Ruby 2.7 on Linux. You're welcome to give us feedback if it is possible to run it with other older versions.<br>
Note: Before using RubyCrumbler, make sure you have downloaded the respective spaCy models (EN: [en_core_web_lg](https://spacy.io/models/en), DE: [de_core_news_lg](https://spacy.io/models/de)).<br>

Linux:

* If an error occurs while installing tk gem in Linux, try this: [tk-dev installation](https://dev.to/kojix2/installing-ruby-tk-on-ubuntu-1d86).
* If an error occurs while installing ruby-spacy, make sure that you have installed Python with spaCy library.
* Make sure that you have installed ruby-dev package.

## GUI

MacOS | Windows | Linux
| :---: | :---: | :---:
![mac_31](https://user-images.githubusercontent.com/72874215/159339948-b7ae1bf2-60c1-4dae-ac1a-4e13a6048ef0.gif)|![windows_4](https://user-images.githubusercontent.com/72874215/160242473-c38439be-0955-4e89-9f3f-b3d0567531fd.gif)|![rubycrumbler_linux](https://user-images.githubusercontent.com/72874215/160242460-99af1c8c-b43f-458d-bd69-1274a0bd9814.gif)

### Issues & Future Tasks

General:

* The GUI window cannot be reduced in width so far. In general, we recommend opening and using in full-screen mode.
* Using [threads](https://ruby-doc.org/core-2.5.0/Thread.html) for multiple execution.
* Adding stemming as a feature in the NLP pipeline.
* We recommend that texts are encoded in UTF-8.<br>

macOS:

* The URL in the File Upload area can only be inserted into the field via right click and "paste". The shortcut "cmd/ctrl + v" does not work.

## Description of Features

***Pre-Processing***<br>
**Data Cleaning:** This includes removing redundant whitespaces, punctuation (redundant dots), special symbols (e.g., line break, new line), hash tags, HTML tags, and URLs.<br>
**Normalization:** This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark).<br>
**Normalization (lowercase):** This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting the text into lowercase.<br>
**Normalization (contractions):** This includes removing punctuation symbols (dot, colon, comma, semicolon, exclamation and question mark) as well as converting contractions (abbreviation for a sequence of words like “don’t”) into their original form (e.g., do not). Note: German contractions are always converted with the definite article and include only very colloquial contractions (unterm - unter dem). Contractions like “zum” are not transformed into “zu dem”, because expressions like “zum Beispiel” usually need to remain unchanged. The list of contractions can be found in the source code and can be customized as needed.<br>

***Natural Language Processing – Tasks***<br>
**Tokenization:** This includes splitting the pre-processed data into individual characters or tokens.<br>
**Stopword Removal:** Stopwords are words that do not carry much meaning but are important grammatically, for example “to” or “but”. This feature includes the removal of stopwords.<br>
**Lemmatization:** This involves the reduction of words to their semantic base forms by the elimination of inflectional suffixes such as plural markers on nouns or verb form markers. Irregular verb roots are replaced by the infinitive form. Word classes derived from a base form (e.g. adverbs derived from adjectives) are allocated to their respective lemmas. Examples: <i>computing – compute, sung – sing, obviously – obvious</i>.<br>
**Part-of-Speech Tagging (POS):** This includes identifying and labeling the parts of speech of text data.<br>
**Named Entity Recognition (NER):** This includes labeling the so-called named entities in the data such as persons, organizations, and places. Note: In order to better identify named entities, it is recommended not to convert the text to only lowercase letters during pre-processing (i.e., do not apply "Normalization (lowercase)").<br>

## File Naming Convention

To enable a quick identification and location of your converted document depending on the feature applied, the following file naming convention is used.<br>
Abbreviations are added to the source file name to indicate the features that have been applied to the document. The suffix of the new file name indicates the ouput file for the corresponding feature. For example, the file named "myfirsttext_cl_nlc_tok.txt" is the output file of the tokenization step.<br><br>
**Overview of the feature abbreviations:**

* Data cleaning = cl
* Normalization = n
* Normalization (lowercase) = l
* Normalization (contractions) = c
* Tokenization = tok
* Stopword Removal = sw
* Lemmatization = lem
* Part-of-Speech Tagging = pos
* Named Entity Recognition = ner

For each feature step the output format is TXT. POS tagging and NER are additionally saved in CSV and XML output format.

## Pipeline Structure of RubyCrumbler

The program is built based on the following pipeline structure.<br>
![alt text](https://github.com/joh-ga/RubyCrumbler/blob/43bf06a8dc118f2e5c9eac252f3b7158fb00b5fe/img/rubycrumbler_pipeline.png)<br>

## Project Structure

```bash
.
├── bin/
│   └── rubycrumbler           # Executable script
├── lib/
│   ├── ruby_crumbler.rb       # Main module file
│   └── ruby_crumbler/
│       ├── pipeline/
│       │   └── features.rb    # Text processing features
│       └── gui/
│           └── crumbler_gui.rb # GUI implementation
├── spec/                      # Tests directory
├── Gemfile                    # Dependencies
└── README.md                  # Documentation
```

## Requirements

* Ruby 3.2.2 or higher
* Python with SpaCy installed
* Required SpaCy models (en_core_web_lg, de_core_news_lg)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Developed by Laura Bernardy, Nora Dirlam, Jakob Engel, and Johanna Garthe.
Refactor by Robert Pannick
