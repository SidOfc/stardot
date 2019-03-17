# frozen_string_literal: true

RSpec.describe Stardot::Fragment do
  def reply_prompt_with(input, question, options, **settings)
    with_cli_args '-i' do
      frag = fragment

      allow(frag).to receive(:read_input_char).and_return(input)
      frag.prompt(question, options, **settings)
    end
  end

  describe '#prompt' do
    it 'prompts for user input' do
      answer = reply_prompt_with 'y', 'prompt text', %w[y n]

      expect(answer).to be 'y'
    end

    it 'uses selected option when enter is pressed' do
      answer = reply_prompt_with '', 'prompt text', %w[y n], selected: 'y'

      expect(answer).to be 'y'
    end
  end
end
