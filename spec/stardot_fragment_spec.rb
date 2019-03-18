# frozen_string_literal: true

RSpec.describe Stardot::Fragment do
  describe '#prompt' do
    it 'prompts for user input' do
      answer = reply_with('y') { prompt 'prompt text', %w[y n] }

      expect(answer).to be 'y'
    end

    it 'uses selected option when enter is pressed' do
      answer = reply_with('') { prompt 'prompt text', %w[y n], selected: 'y' }

      expect(answer).to be 'y'
    end
  end
end
