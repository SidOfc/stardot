# frozen_string_literal: true

RSpec.describe 'Asdf' do
  let :asdf do
    asdf = as_plugin :asdf
    allow(asdf).to receive(:plugin?)
    allow(asdf).to receive(:perform_installation)
    allow(asdf).to receive(:perform_language_installation)
    asdf
  end

  describe '#install' do
    it 'fails when language plugin can not be installed' do
      allow(asdf).to receive(:plugin_exists?).and_return(false)

      asdf.install :does_not_exist, versions: :latest

      expect(statuses.last).to eq :error
    end

    it 'installs the language plugin if it is not installed' do
      expect(asdf).to receive(:perform_language_installation)

      allow(asdf).to receive(:plugin_exists?).and_return(true)

      asdf.install :ruby
    end

    it 'installs when language plugin is installed' do
      allow(asdf).to receive(:plugin?).and_return(true)
      allow(asdf).to receive(:language_installed?).and_return(false)

      asdf.install :ruby, versions: '2.5.0', async: false

      expect(statuses.last).to eq :ok
    end

    it 'skips when specified language version is already installed' do
      allow(asdf).to receive(:plugin?).and_return(true)
      allow(asdf).to receive(:language_installed?).and_return(true)

      asdf.install :ruby, versions: '3.0.0', async: false

      expect(statuses.last).to eq :info
    end

    it 'force reinstalls specified language version with cli flag "-y"' do
      allow(asdf).to receive(:plugin?).and_return(true)
      allow(asdf).to receive(:language_installed?).and_return(true)

      with_cli_args('-y') { asdf.install :ruby, versions: '3.0.0', async: false }

      expect(statuses.last).to eq :info
    end

    it 'performs uninstallation before reinstalling a language' do
      expect(asdf).to receive(:perform_uninstall)

      allow(asdf).to receive(:plugin?).and_return(true)
      allow(asdf).to receive(:language_installed?).and_return(true)

      with_cli_args('-y') do
        asdf.install :ruby, versions: :latest, async: false
      end

      expect(statuses.last).to eq :info
    end

    it 'prompts to reinstall specified language version with cli flag "-i"' do
      allow(asdf).to receive(:plugin?).and_return(true)
      allow(asdf).to receive(:language_installed?).and_return(true)

      with_cli_args('-i') do
        reply_with('y', asdf) { install :ruby, versions: '3.0.0', async: false }
      end

      expect(statuses.last).to eq :info
    end

    it 'installs multiple versions' do
      allow(asdf).to receive(:plugin?).and_return(true)
      allow(asdf).to receive(:language_installed?).and_return(false)

      asdf.process { install :ruby, versions: %w[3.0.0 3.1.0 3.2.0] }

      expect(statuses.last(3)).to all eq(:ok)
    end
  end
end
