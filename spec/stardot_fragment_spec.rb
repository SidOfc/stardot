# frozen_string_literal: true

RSpec.describe Stardot::Fragment do
  let(:frag) { fragment }

  it 'creates a #status_echo wrapped method for every status' do
    Stardot::Fragment::STATUSES.each do |status|
      expect(fragment).to respond_to status
    end
  end

  describe '#prompt' do
    it 'prompts for user input' do
      answer = reply_with('y') { prompt 'prompt text', %w[y n] }

      expect(answer).to eq 'y'
    end

    it 'uses selected option when enter is pressed' do
      answer = reply_with('') { prompt 'prompt text', %w[y n], selected: 'y' }

      expect(answer).to eq 'y'
    end
  end

  describe '#interactive?' do
    it 'is true when cli flag "-i" is included' do
      allow(STDIN).to receive(:isatty).and_return(true)

      expect(with_cli_args('-i') { frag.interactive? }).to eq true
    end

    it 'is true when { interactive: true } option is passed' do
      allow(STDIN).to receive(:isatty).and_return(true)

      expect(fragment(interactive: true).interactive?).to eq true
    end

    it 'is false when STDIN is not a tty and cli flag "-i" is included' do
      allow(STDIN).to receive(:isatty).and_return(false)

      expect(with_cli_args('-i') { frag.interactive? }).to eq false
    end

    it ['is false when STDIN is not a tty and',
        '{ interactive: true } option is passed'].join(' ') do
      allow(STDIN).to receive(:isatty).and_return(false)

      expect(fragment(interactive: true).interactive?).to eq false
    end
  end

  describe '#process' do
    it 'runs and clears prerequisites when called for the first time' do
      allow(frag.class).to receive(:which).with(:program1).and_return(false)
      allow(frag.class).to receive(:which).with(:program2).and_return(false)

      frag.class.missing_binary(:program1) { 'install binary "program1"' }
      frag.class.missing_binary(:program2) { 'install binary "program2"' }

      expect(frag.class.prerequisites.size).to eq 2

      frag.process

      expect(frag.class.prerequisites.size).to eq 0
    end
  end

  describe '.missing_file' do
    let!(:test_path) { File.join Helpers::ROOT_DIR, 'bogus', 'file.txt' }

    it 'adds a prerequisite if file does not exist' do
      allow(File).to receive(:exist?).with(test_path).and_return(false)
      frag.class.missing_file(test_path) { nil }

      expect(frag.class.prerequisites).not_to be_empty
    end

    it 'does not add a prerequisite if file exists' do
      allow(File).to receive(:exist?).with(test_path).and_return(true)
      frag.class.missing_file(test_path) { nil }

      expect(frag.class.prerequisites).to be_empty
    end
  end

  describe '.missing_binary' do
    it 'adds a prerequisite if command does not exist' do
      allow(frag.class).to receive(:which).with(:program).and_return(false)
      frag.class.missing_binary(:program) { nil }

      expect(frag.class.prerequisites).not_to be_empty
    end

    it 'does not add a prerequisite if command exists' do
      allow(frag.class).to receive(:which).with(:program).and_return(true)
      frag.class.missing_binary(:program) { nil }

      expect(frag.class.prerequisites).to be_empty
    end
  end
end
