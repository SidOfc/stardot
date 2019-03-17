# frozen_string_literal: true

RSpec.describe 'Symlink' do
  DEST_DIR    = File.join Helpers::ROOT, 'symlink'
  SRC_FILE    = File.join Helpers::ROOT, 'stardot.rb'
  DEST_FILE   = File.join DEST_DIR,      'stardot.rb'
  SRC_FOLDER  = File.join Helpers::ROOT, 'folder/'
  DEST_FOLDER = File.join DEST_DIR,      'folder/'

  before :each do
    FileUtils.mkdir_p DEST_DIR
  end

  after :each do
    FileUtils.rm_rf DEST_DIR
  end

  describe '#ln' do
    it 'creates a file symlink' do
      as_plugin :symlink do
        dest DEST_DIR

        ln SRC_FILE, DEST_FILE
      end

      expect(File.symlink?(DEST_FILE)).to be true
    end

    it 'creates a directory symlink' do
      as_plugin :symlink do
        dest DEST_DIR

        ln SRC_FOLDER, DEST_FOLDER
      end

      expect(File.directory?(DEST_FOLDER)).to be true
    end

    it 'errors when source location does not exist' do
      as_plugin :symlink do
        dest DEST_DIR

        ln '_', DEST_FILE
      end

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end

    it 'overwrites an existing symlink using force: true' do
      as_plugin :symlink do
        dest DEST_DIR

        ln SRC_FILE, DEST_FILE
        ln SRC_FILE, DEST_FILE, force: true
      end

      expect(Stardot.logger.entries.last[:status]).to eq :ok
    end

    it 'overwrites an existing symlink using cli flag "-y"' do
      with_cli_args '-y' do
        as_plugin :symlink do
          dest DEST_DIR

          ln SRC_FILE, DEST_FILE
          ln SRC_FILE, DEST_FILE
        end
      end

      expect(Stardot.logger.entries.last[:status]).to eq :ok
    end

    it 'does not overwrite an existing symlink' do
      as_plugin :symlink do
        dest DEST_DIR

        ln SRC_FILE, DEST_FILE
        ln SRC_FILE, DEST_FILE
      end

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end
  end
end
