# frozen_string_literal: true

RSpec.describe 'Symlink' do
  SRC_FILE  = File.join Helpers::ROOT, 'stardot.rb'
  DEST_DIR  = File.join Helpers::ROOT, 'symlink'
  DEST_FILE = File.join DEST_DIR, 'stardot.rb'

  before :each do
    FileUtils.mkdir_p DEST_DIR
  end

  after :each do
    FileUtils.rm_rf DEST_DIR
  end

  describe '#ln' do
    it 'can create a symlink' do
      as_plugin :symlink do
        base DEST_DIR

        ln SRC_FILE, DEST_FILE
      end

      expect(File.symlink?(DEST_FILE)).to be true
    end

    it 'errors out when source file does not exist' do
      as_plugin :symlink do
        base DEST_DIR

        ln '_', DEST_FILE
      end

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end

    it 'does not overwrite existing symlinks by default' do
      as_plugin :symlink do
        base DEST_DIR

        ln SRC_FILE, DEST_FILE
        ln SRC_FILE, DEST_FILE
      end

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end

    it 'can force overwrite an existing symlink' do
      as_plugin :symlink do
        base DEST_DIR

        ln SRC_FILE, DEST_FILE
        ln SRC_FILE, DEST_FILE, force: true
      end

      expect(Stardot.logger.entries.last[:status]).to eq :ok
    end
  end
end
