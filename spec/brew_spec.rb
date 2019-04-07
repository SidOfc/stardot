# frozen_string_literal: true

RSpec.describe 'Brew' do
  let :brew do
    brew = as_plugin :brew

    allow(brew).to receive_messages(
      install_homebrew:     true,
      perform_installation: true,
      perform_tap:          true,
      perform_update:       true,
      packages:             {},
      outdated_packages:    {},
      tapped:               []
    )

    brew
  end

  it 'installs homebrew if it is not installed' do
    expect(brew).to receive :install_homebrew

    allow(brew.class).to receive(:which).and_return false

    # force execute missing_binary since tests are run in random
    # order which means we cannot ensure missing_binary has not
    # yet been run and removed prior to this test.
    brew.class.missing_binary :brew, :install_homebrew
    brew.process
  end

  describe '#tap' do
    it 'taps an untapped keg' do
      expect(brew).to receive :perform_tap

      allow(brew).to receive(:untapped?).and_return true

      brew.tap 'mscharley/homebrew'

      expect(statuses.last).to eq :ok
    end

    it 'does not tap an already tapped keg' do
      expect(brew).not_to receive :perform_tap

      allow(brew).to receive(:untapped?).and_return false

      brew.tap 'mscharley/homebrew'

      expect(statuses.last).to eq :info
    end
  end

  describe '#install' do
    it 'installs a package' do
      allow(brew).to receive(:brew_info).and_return(
        name: 'asdf', version: '0.7.0'
      )

      brew.process { install :asdf }

      expect(statuses.last).to eq :ok
    end

    it 'skips when package is already installed' do
      allow(brew).to receive(:packages).and_return 'asdf' => '0.7.0'

      brew.process { install :asdf }

      expect(statuses.last).to eq :info
    end

    it 'prompts to update an installed package with cli flag "-i"' do
      expect(brew).to receive :prompt

      allow(brew).to receive(:version_of).with(:fzf).and_return '0.17.0'
      allow(brew).to receive(:outdated_packages).and_return 'fzf' => '0.17.5'

      with_cli_args '-i' do
        reply_with(one_of('y', 'n'), brew) { install :fzf }
      end
    end

    it 'does not update without cli flag "-y" or "-i"' do
      allow(brew).to receive(:version_of).with(:fzf).and_return '0.17.0'
      allow(brew).to receive(:outdated_packages).and_return 'fzf' => '0.17.5'

      brew.install :fzf

      expect(statuses.last).to eq :warn
    end

    it 'updates without prompting when cli flag "-y" is passed' do
      expect(brew).to receive(:perform_update).with :fzf

      allow(brew).to receive(:version_of).with(:fzf).and_return '0.17.0'
      allow(brew).to receive(:outdated_packages).and_return 'fzf' => '0.17.5'

      with_cli_args('-y', '-i') { brew.install :fzf }
    end

    it 'runs brew tap when supplied and package is not installed' do
      expect(brew).to receive(:perform_tap).with 'mscharley/homebrew'

      allow(brew).to receive :version_of
      allow(brew).to receive(:brew_info).and_return version: '0.2.9'

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end

    it 'runs brew tap when supplied and package can be upgraded' do
      expect(brew).to receive(:perform_tap).with 'mscharley/homebrew'

      allow(brew).to receive(:version_of).with(:alacritty).and_return '0.2.6'
      allow(brew).to receive(:outdated_packages).and_return(
        'alacritty' => '0.2.9'
      )

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end

    it 'does not run brew tap when supplied tap is already installed' do
      expect(brew).not_to receive :perform_tap

      allow(brew).to receive(:version_of).with :alacritty
      allow(brew).to receive(:tapped).and_return ['mscharley/homebrew']
      allow(brew).to receive(:brew_info).with(:alacritty).and_return(
        version: '0.2.9'
      )

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end

    it ['does not run brew tap when supplied',
        'and package is already up to date'].join(' ') do
      expect(brew).not_to receive :perform_tap

      allow(brew).to receive(:version_of).and_return '0.2.9'

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end
  end
end
