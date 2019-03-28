# frozen_string_literal: true

RSpec.describe 'Brew' do
  let :brew do
    brew = as_plugin :brew
    allow(brew).to receive(:install_homebrew)
    allow(brew).to receive(:perform_installation)
    allow(brew).to receive(:perform_tap)
    allow(brew).to receive(:perform_update)
    allow(brew).to receive(:packages).and_return({})
    allow(brew).to receive(:outdated_packages).and_return({})
    allow(brew).to receive(:tapped).and_return([])
    brew
  end

  it 'installs homebrew if it is not installed' do
    allow(brew.class).to receive(:which).and_return(false)
    brew.class.missing_binary :brew, :install_homebrew

    expect(brew).to receive :install_homebrew

    brew.process
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
      allow(brew).to receive(:packages).and_return('asdf' => '0.7.0')

      brew.process { install :asdf }

      expect(statuses.last).to eq :info
    end

    it 'prompts to update an installed package with cli flag "-i"' do
      expect(brew).to receive(:prompt)

      allow(brew).to receive(:version_of).with(:fzf).and_return('0.17.0')
      allow(brew).to receive(:outdated_packages).and_return('fzf' => '0.17.5')

      with_cli_args '-i' do
        reply_with(one_of('y', 'n'), brew) { install :fzf }
      end
    end

    it 'updates without prompting when cli flag "-y" is passed' do
      expect(brew).to receive(:perform_update).with(:fzf)

      allow(brew).to receive(:version_of).with(:fzf).and_return('0.17.0')
      allow(brew).to receive(:outdated_packages).and_return('fzf' => '0.17.5')

      with_cli_args '-y', '-i' do
        brew.install :fzf
      end
    end

    it 'runs brew tap when supplied and package is not installed' do
      expect(brew).to receive(:perform_tap).with('mscharley/homebrew')

      allow(brew).to receive(:version_of).and_return(nil)
      allow(brew).to receive(:brew_info).and_return(version: '0.2.9')

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end

    it 'runs brew tap when supplied and package can be upgraded' do
      expect(brew).to receive(:perform_tap).with('mscharley/homebrew')

      allow(brew).to receive(:version_of).with(:alacritty).and_return('0.2.6')
      allow(brew).to receive(:outdated_packages).and_return('alacritty' => '0.2.9')

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end

    it 'does not run brew tap when supplied tap is already installed' do
      expect(brew).not_to receive(:perform_tap)

      allow(brew).to receive(:version_of).with(:alacritty).and_return(nil)
      allow(brew).to receive(:brew_info).with(:alacritty).and_return(version: '0.2.9')
      allow(brew).to receive(:tapped).and_return(['mscharley/homebrew'])

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end

    it 'does not run brew tap when supplied and package is already up to date' do
      expect(brew).not_to receive(:perform_tap)

      allow(brew).to receive(:version_of).and_return('0.2.9')

      brew.install :alacritty, tap: 'mscharley/homebrew'
    end
  end
end
