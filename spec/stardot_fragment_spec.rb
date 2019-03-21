# frozen_string_literal: true

RSpec.describe Stardot::Fragment do
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
      expect(with_cli_args('-i') { fragment.interactive? }).to eq true
    end

    it 'is true when { interactive: true } option is passed' do
      allow(STDIN).to receive(:isatty).and_return(true)
      expect(fragment(interactive: true).interactive?).to eq true
    end

    it 'is false when STDIN is not a tty and cli flag "-i" is included' do
      allow(STDIN).to receive(:isatty).and_return(false)
      expect(with_cli_args('-i') { fragment.interactive? }).to eq false
    end

    it 'is false when STDIN is not a tty and { interactive: true } option is passed' do
      allow(STDIN).to receive(:isatty).and_return(false)
      expect(fragment(interactive: true).interactive?).to eq false
    end
  end
end
