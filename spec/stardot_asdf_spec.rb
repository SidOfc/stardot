# frozen_string_literal: true

RSpec.describe 'Asdf < Stardot::Fragment' do
  describe '#install' do
    it 'fails when language plugin is not installed' do
      asdf = as_plugin :asdf

      asdf.process { install :does_not_exist, versions: :latest }

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end

    it 'installs when language plugin is installed' do
      asdf = as_plugin :asdf

      allow(asdf).to receive(:plugin?).with(:ruby).and_return(true)
      allow(asdf).to receive(:persist).and_return(true)

      asdf.process { install :ruby, versions: '2.5.0' }

      expect(Stardot.logger.entries.last[:status]).to eq :ok
    end

    it 'skips when specified language version is already installed' do
      asdf = as_plugin :asdf

      allow(asdf).to receive(:persist).and_return(true)
      allow(asdf).to receive(:plugin?).with(:ruby).and_return(true)
      allow(asdf).to receive(:language_installed?)
        .with(:ruby, '3.0.0').and_return(true)

      asdf.process { install :ruby, versions: '3.0.0' }

      expect(Stardot.logger.entries.last[:status]).to eq :info
    end
  end
end
