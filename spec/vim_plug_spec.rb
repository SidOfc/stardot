# frozen_string_literal: true

RSpec.describe 'VimPlug' do
  let :vim_plug do
    vim_plug = as_plugin :vim_plug
    vim_plug.root File.join(Helpers::ROOT_DIR, 'vim_plug')

    allow(vim_plug).to receive_messages(
      install_plug:  true,
      perform_clone: true,
      perform_pull:  true
    )

    vim_plug
  end

  before(:each) { FileUtils.mkdir_p vim_plug.root }
  after(:each) { FileUtils.rm_rf vim_plug.root }

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

    it 'can install a specific branch' do
      allow(vim_plug).to receive(:plug?).and_return false
      allow(vim_plug).to receive(:install_plug).and_call_original
      allow(vim_plug).to receive(:perform_clone).and_call_original

      vim_plug.plug 'styled-components/vim-styled-components', branch: :main

      vim_plug.process

      pp vim_plug.path_to('vim-styled-components')
      expect(git_branch(vim_plug.path_to('vim-styled-components'))).to(
        eq('main')
      )
    end
  end
end
