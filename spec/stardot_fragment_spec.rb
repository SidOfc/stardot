# frozen_string_literal: true

RSpec.describe Stardot::Fragment do
  describe "#prompt" do
    it 'prompts for user input' do
      answer = nil

      with_cli_args '-i' do
        frag = fragment

        allow(frag).to receive(:read_input_char).and_return('y')
        answer = frag.prompt('Can I ask a question?', %w[y n])
      end

      expect(answer).to be 'y'
    end

    it 'uses selected option when enter is pressed' do
      answer = nil

      with_cli_args '-i' do
        frag = fragment

        allow(frag).to receive(:read_input_char).and_return('')
        answer = frag.prompt 'Can I ask a question?', %w[y n], selected: 'y'
      end

      expect(answer).to be 'y'
    end
  end
end
