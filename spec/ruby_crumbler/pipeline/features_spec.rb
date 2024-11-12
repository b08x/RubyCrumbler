require 'spec_helper'

RSpec.describe RubyCrumbler::Pipeline::Features do
  let(:features) { described_class.new }
  let(:test_dir) { File.join(Dir.pwd, 'spec', 'fixtures') }
  let(:test_file) { File.join(test_dir, 'test.txt') }
  let(:test_file_de) { File.join(test_dir, 'test_de.txt') }
  let(:large_file) { File.join(test_dir, 'large.txt') }

  before(:each) do
    FileUtils.mkdir_p(test_dir)
    File.write(test_file, "Hello, World! This is a test.\nIt's working, isn't it?")
    File.write(test_file_de, "Hallo, Welt! Dies ist ein Test.\nEs funktioniert, oder?")
  end

  after(:each) do
    FileUtils.rm_rf(test_dir)
  end

  describe '#newproject' do
    context 'with valid input' do
      it 'creates a new project directory' do
        features.newproject(test_file, 'test_project')
        expect(Dir.exist?('test_project')).to be true
        FileUtils.rm_rf('test_project')
      end

      it 'handles existing project names' do
        features.newproject(test_file, 'test_project')
        features.newproject(test_file, 'test_project')
        expect(Dir.exist?('test_project2')).to be true
        FileUtils.rm_rf(['test_project', 'test_project2'])
      end
    end

    context 'with invalid input' do
      it 'raises error for non-existent file' do
        expect {
          features.newproject('nonexistent.txt', 'test_project')
        }.to raise_error(ArgumentError, /File not found/)
      end

      it 'raises error for unsupported file type' do
        invalid_file = File.join(test_dir, 'test.pdf')
        File.write(invalid_file, 'test content')
        expect {
          features.newproject(invalid_file, 'test_project')
        }.to raise_error(ArgumentError, /Unsupported file type/)
      end

      it 'raises error for file size exceeding limit' do
        File.write(large_file, 'x' * (RubyCrumbler::Config::MAX_FILE_SIZE + 1))
        expect {
          features.newproject(large_file, 'test_project')
        }.to raise_error(ArgumentError, /File too large/)
      end
    end
  end

  describe '#cleantext' do
    before do
      features.newproject(test_file, 'test_project')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    it 'cleans the text file' do
      features.cleantext
      cleaned_file = File.join('test_project', 'test_cl.txt')
      expect(File.exist?(cleaned_file)).to be true
      content = File.read(cleaned_file)
      expect(content).not_to include('!')
      expect(content).not_to include(',')
    end

    it 'handles empty files' do
      File.write(File.join('test_project', 'test.txt'), '')
      expect { features.cleantext }.not_to raise_error
    end
  end

  describe '#normalize' do
    before do
      features.newproject(test_file, 'test_project')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    context 'with English text' do
      it 'converts text to lowercase' do
        features.normalize(false, 'EN', true)
        normalized_file = Dir.glob(File.join('test_project', '*_nl.txt')).first
        expect(File.exist?(normalized_file)).to be true
        content = File.read(normalized_file)
        expect(content).to eq(content.downcase)
      end

      it 'expands contractions' do
        features.normalize(true, 'EN', false)
        normalized_file = Dir.glob(File.join('test_project', '*_nc.txt')).first
        expect(File.exist?(normalized_file)).to be true
        content = File.read(normalized_file)
        expect(content).not_to include("isn't")
        expect(content).to include('is not')
      end

      it 'combines lowercase and contractions' do
        features.normalize(true, 'EN', true)
        normalized_file = Dir.glob(File.join('test_project', '*_nlc.txt')).first
        expect(File.exist?(normalized_file)).to be true
        content = File.read(normalized_file)
        expect(content).to eq(content.downcase)
        expect(content).not_to include("isn't")
        expect(content).to include('is not')
      end
    end

    context 'with German text' do
      before do
        FileUtils.rm_rf('test_project')
        features.newproject(test_file_de, 'test_project')
      end

      it 'handles German contractions' do
        features.normalize(true, 'DE', false)
        normalized_file = Dir.glob(File.join('test_project', '*_nc.txt')).first
        expect(File.exist?(normalized_file)).to be true
        content = File.read(normalized_file)
        expect(content).not_to include("gibt's")
        expect(content).to include('gibt es')
      end
    end
  end

  describe '#tokenizer' do
    before do
      features.newproject(test_file, 'test_project')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    it 'tokenizes English text' do
      features.tokenizer('EN')
      tokenized_file = Dir.glob(File.join('test_project', '*_tok.txt')).first
      expect(File.exist?(tokenized_file)).to be true
      content = File.read(tokenized_file)
      expect(content).to include('Hello')
      expect(content).to include('World')
    end

    it 'handles empty input' do
      File.write(File.join('test_project', 'test.txt'), '')
      expect { features.tokenizer('EN') }.not_to raise_error
    end

    it 'validates language input' do
      expect { features.tokenizer('FR') }.to raise_error(ArgumentError, /Unsupported language/)
    end
  end

  describe '#stopwordsclean' do
    before do
      features.newproject(test_file, 'test_project')
      features.tokenizer('EN')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    it 'removes English stopwords' do
      features.stopwordsclean('EN')
      cleaned_file = Dir.glob(File.join('test_project', '*_nost.txt')).first
      expect(File.exist?(cleaned_file)).to be true
      content = File.read(cleaned_file)
      expect(content).not_to include('is')
      expect(content).not_to include('a')
    end

    it 'handles German stopwords' do
      FileUtils.rm_rf('test_project')
      features.newproject(test_file_de, 'test_project')
      features.tokenizer('DE')
      features.stopwordsclean('DE')
      cleaned_file = Dir.glob(File.join('test_project', '*_nost.txt')).first
      expect(File.exist?(cleaned_file)).to be true
      content = File.read(cleaned_file)
      expect(content).not_to include('ist')
      expect(content).not_to include('ein')
    end
  end

  describe '#lemmatizer' do
    before do
      features.newproject(test_file, 'test_project')
      features.tokenizer('EN')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    it 'lemmatizes English text' do
      features.lemmatizer('EN')
      lemmatized_file = Dir.glob(File.join('test_project', '*_lem.txt')).first
      expect(File.exist?(lemmatized_file)).to be true
      content = File.read(lemmatized_file)
      expect(content).to include('lemma:be')  # "is" -> "be"
    end

    it 'handles German text' do
      FileUtils.rm_rf('test_project')
      features.newproject(test_file_de, 'test_project')
      features.tokenizer('DE')
      features.lemmatizer('DE')
      lemmatized_file = Dir.glob(File.join('test_project', '*_lem.txt')).first
      expect(File.exist?(lemmatized_file)).to be true
      content = File.read(lemmatized_file)
      expect(content).to include('lemma:sein')  # "ist" -> "sein"
    end
  end

  describe '#tagger' do
    before do
      features.newproject(test_file, 'test_project')
      features.tokenizer('EN')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    it 'performs POS tagging for English' do
      features.tagger('EN')
      pos_file = Dir.glob(File.join('test_project', '*_pos.txt')).first
      expect(File.exist?(pos_file)).to be true
      expect(File.exist?(pos_file.sub('.txt', '.csv'))).to be true
      expect(File.exist?(pos_file.sub('.txt', '.xml'))).to be true
      content = File.read(pos_file)
      expect(content).to include('pos:NOUN')  # "World" should be tagged as noun
    end

    it 'generates valid XML output' do
      features.tagger('EN')
      xml_file = Dir.glob(File.join('test_project', '*_pos.xml')).first
      expect { Nokogiri::XML(File.read(xml_file)) { |config| config.strict } }.not_to raise_error
    end
  end

  describe '#ner' do
    before do
      features.newproject(test_file, 'test_project')
      features.tokenizer('EN')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    it 'performs named entity recognition for English' do
      features.ner('EN')
      ner_file = Dir.glob(File.join('test_project', '*_ner.txt')).first
      expect(File.exist?(ner_file)).to be true
      expect(File.exist?(ner_file.sub('.txt', '.csv'))).to be true
      expect(File.exist?(ner_file.sub('.txt', '.xml'))).to be true
    end

    it 'generates valid XML output' do
      features.ner('EN')
      xml_file = Dir.glob(File.join('test_project', '*_ner.xml')).first
      expect { Nokogiri::XML(File.read(xml_file)) { |config| config.strict } }.not_to raise_error
    end
  end
end
