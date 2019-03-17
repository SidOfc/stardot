# frozen_string_literal: true

RSpec.describe 'Asdf < Stardot::Fragment' do
  describe '#install' do
    it 'fails when language plugin is not installed' do
      as_plugin :asdf do
        install :does_not_exist, versions: :latest
      end

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end

    it 'installs when language plugin is installed' do
      asdf = as_plugin :asdf

      allow(asdf).to receive(:plugin?).with(:ruby).and_return(true)
      allow(asdf).to receive(:persist).and_return(true)

      asdf.process { install :ruby, versions: '2.5.0' }

      expect(Stardot.logger.entries.last[:status]).to eq :ok
    end
  end
end
