# frozen_string_literal: true

RSpec.describe 'Brew' do
  let :brew do
    brew = as_plugin :brew
    allow(brew).to receive(:install_homebrew).and_return(true)
    allow(brew).to receive(:persist_installation).and_return(true)
    allow(brew).to receive(:perform_update).and_return(true)
    allow(brew).to receive(:packages).and_return({})
    allow(brew).to receive(:outdated_packages).and_return({})
    brew
  end

  it 'installs homebrew if it is not installed' do
    allow(brew.class).to receive(:which).with(:brew).and_return(false)
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
      expect(brew).to receive(:perform_update)

      allow(brew).to receive(:version_of).with(:fzf).and_return('0.17.0')
      allow(brew).to receive(:outdated_packages).and_return('fzf' => '0.17.5')

      with_cli_args '-y' do
        brew.install :fzf
      end

      expect(statuses.last).to eq :ok
    end
  end
end
