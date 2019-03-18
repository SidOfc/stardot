# frozen_string_literal: true

RSpec.describe 'Brew' do
  describe '#install' do
    let :brew do
      brew = as_plugin :brew
      allow(brew).to receive(:persist_installation).and_return(true)
      allow(brew).to receive(:perform_update).and_return(true)
      allow(brew).to receive(:packages).and_return({})
      brew
    end

    it 'installs a package' do
      brew.process { install :asdf }

      expect(statuses.last).to eq :ok
    end

    it 'skips when package is already installed' do
      brew.process { 2.times { install :asdf } }

      expect(statuses.last(2)).to eq %i[ok info]
    end
  end
end
