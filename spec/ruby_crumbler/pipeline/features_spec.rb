require 'spec_helper'

RSpec.describe RubyCrumbler::Pipeline::Features do
  let(:features) { described_class.new }
  let(:test_dir) { File.join(Dir.pwd, 'spec', 'fixtures') }
  let(:test_file) { File.join(test_dir, 'test.txt') }

  before(:each) do
    FileUtils.mkdir_p(test_dir)
    File.write(test_file, "Hello, World! This is a test.\nIt's working, isn't it?")
  end

  after(:each) do
    FileUtils.rm_rf(test_dir)
  end

  describe '#newproject' do
    it 'creates a new project directory' do
      features.newproject(test_file, 'test_project')
      expect(Dir.exist?('test_project')).to be true
      FileUtils.rm_rf('test_project')
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
  end

  describe '#normalize' do
    before do
      features.newproject(test_file, 'test_project')
    end

    after do
      FileUtils.rm_rf('test_project')
    end

    context 'with lowercase option' do
      it 'converts text to lowercase' do
        features.normalize(false, 'EN', true)
        normalized_file = Dir.glob(File.join('test_project', '*_nl.txt')).first
        expect(File.exist?(normalized_file)).to be true
        content = File.read(normalized_file)
        expect(content).to eq(content.downcase)
      end
    end

    context 'with contractions option' do
      it 'expands contractions' do
        features.normalize(true, 'EN', false)
        normalized_file = Dir.glob(File.join('test_project', '*_nc.txt')).first
        expect(File.exist?(normalized_file)).to be true
        content = File.read(normalized_file)
        expect(content).not_to include("isn't")
        expect(content).to include('is not')
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

    it 'tokenizes the text' do
      features.tokenizer('EN')
      tokenized_file = Dir.glob(File.join('test_project', '*_tok.txt')).first
      expect(File.exist?(tokenized_file)).to be true
      content = File.read(tokenized_file)
      expect(content).to include('Hello')
      expect(content).to include('World')
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

    it 'removes stopwords' do
      features.stopwordsclean('EN')
      cleaned_file = Dir.glob(File.join('test_project', '*_nost.txt')).first
      expect(File.exist?(cleaned_file)).to be true
      content = File.read(cleaned_file)
      expect(content).not_to include('is')
      expect(content).not_to include('a')
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

    it 'lemmatizes the text' do
      features.lemmatizer('EN')
      lemmatized_file = Dir.glob(File.join('test_project', '*_lem.txt')).first
      expect(File.exist?(lemmatized_file)).to be true
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

    it 'performs POS tagging' do
      features.tagger('EN')
      pos_file = Dir.glob(File.join('test_project', '*_pos.txt')).first
      expect(File.exist?(pos_file)).to be true
      expect(File.exist?(pos_file.sub('.txt', '.csv'))).to be true
      expect(File.exist?(pos_file.sub('.txt', '.xml'))).to be true
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

    it 'performs named entity recognition' do
      features.ner('EN')
      ner_file = Dir.glob(File.join('test_project', '*_ner.txt')).first
      expect(File.exist?(ner_file)).to be true
      expect(File.exist?(ner_file.sub('.txt', '.csv'))).to be true
      expect(File.exist?(ner_file.sub('.txt', '.xml'))).to be true
    end
  end
end
