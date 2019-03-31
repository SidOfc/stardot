# frozen_string_literal: true

RSpec.describe 'VimPlug' do
  let :vim_plug do
    vim_plug = as_plugin :vim_plug

    allow(vim_plug).to receive_messages(
      install_plug:  true,
      perform_clone: true,
      perform_fetch: true,
      perform_pull:  true
    )

    vim_plug
  end

  it 'installs vim-plug if it is not installed' do
    expect(vim_plug).to receive :install_plug

    allow(File).to receive(:exist?).with(VimPlug::PLUG_FILE).and_return false

    # force execute missing_file since tests are run in random
    # order which means we cannot ensure missing_file has not
    # yet been run and removed prior to this test.
    vim_plug.class.missing_file VimPlug::PLUG_FILE, :install_plug
    vim_plug.process
  end

  describe '#plug' do
    it 'installs a plug if it is not installed' do
      expect(vim_plug).to receive :perform_clone

      allow(vim_plug).to receive(:plug?).and_return false

      vim_plug.plug 'sidofc/mkdx'

      vim_plug.process
    end

    it 'updates an outdated plug' do
      expect(vim_plug).to receive :perform_pull

      allow(vim_plug).to receive(:plug?).and_return true
      allow(vim_plug).to receive(:up_to_date?).and_return false

      vim_plug.plug 'sidofc/mkdx'

      vim_plug.process
    end
  end
end
