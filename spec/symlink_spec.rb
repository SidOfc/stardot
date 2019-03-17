# frozen_string_literal: true

RSpec.describe 'Symlink < Stardot::Fragment' do
  def dest_symlink?(*loc)
    File.symlink?(File.join(symlink.dest, *loc))
  end

  def statuses
    Stardot.logger.entries.map { |entry| entry[:status] }
  end

  let(:symlink) { as_plugin :symlink }

  before :each do
    symlink.process do
      src Helpers::ROOT
      dest File.join(Helpers::ROOT, 'symlink')
    end

    FileUtils.mkdir_p symlink.dest
  end

  after :each do
    FileUtils.rm_rf symlink.dest
  end

  describe '#ln' do
    it 'creates a file symlink' do
      symlink.process { ln 'stardot.rb', 'stardot.rb' }

      expect(dest_symlink?('stardot.rb')).to be true
    end

    it 'uses source filename when destination is absent' do
      symlink.process { ln 'stardot.rb' }

      expect(dest_symlink?('stardot.rb')).to be true
    end

    it 'creates a directory symlink' do
      symlink.process { ln 'folder/', 'folder/' }

      expect(dest_symlink?('folder')).to be true
    end

    it 'uses source dirname when destination is absent' do
      symlink.process { ln 'folder/' }

      expect(dest_symlink?('folder')).to be true
    end

    it 'errors when source location does not exist' do
      symlink.process { ln '_', 'stardot.rb' }

      expect(statuses.last).to be :error
    end

    it 'does not overwrite an existing symlink' do
      symlink.process { 2.times { ln 'stardot.rb' } }

      expect(statuses.last).to be :error
    end

    it 'overwrites an existing symlink using force: true' do
      symlink.process do
        ln 'stardot.rb'
        ln 'stardot.rb', force: true
      end

      expect(statuses.last).to be :ok
    end

    it 'overwrites an existing symlink using cli flag "-y"' do
      with_cli_args('-y') { symlink.process { 2.times { ln 'stardot.rb' } } }

      expect(statuses.last).to be :ok
    end
  end
end
