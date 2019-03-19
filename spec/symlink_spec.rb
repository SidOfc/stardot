# frozen_string_literal: true

RSpec.describe 'Symlink' do
  def dest_symlink?(*loc)
    File.symlink?(File.join(symlink.dest, *loc))
  end

  let(:symlink) { as_plugin :symlink }

  before :each do
    symlink.process do
      src  Helpers::ROOT_DIR
      dest File.join(Helpers::ROOT_DIR, 'symlink')
    end

    FileUtils.mkdir_p symlink.dest
  end

  after :each do
    FileUtils.rm_rf symlink.dest
  end

  describe '#ln' do
    it 'creates a file symlink' do
      symlink.process { ln 'stardot.rb', 'stardot.rb' }

      expect(dest_symlink?('stardot.rb')).to eq true
    end

    it 'uses source filename when destination is absent' do
      symlink.process { ln 'stardot.rb' }

      expect(dest_symlink?('stardot.rb')).to eq true
    end

    it 'creates a directory symlink' do
      symlink.process { ln 'folder/', 'folder/' }

      expect(dest_symlink?('folder')).to eq true
    end

    it 'uses source dirname when destination is absent' do
      symlink.process { ln 'folder/' }

      expect(dest_symlink?('folder')).to eq true
    end

    it 'errors when source location does not exist' do
      symlink.process { ln '_', 'stardot.rb' }

      expect(statuses.last).to eq :error
    end

    it 'does not overwrite an existing symlink' do
      symlink.process { 2.times { ln 'stardot.rb' } }

      expect(statuses.last).to eq :info
    end

    it 'overwrites an existing symlink using force: true' do
      symlink.process do
        ln 'stardot.rb'
        ln 'stardot.rb', force: true
      end

      expect(statuses.last).to eq :ok
    end

    it 'overwrites an existing symlink using cli flag "-y"' do
      with_cli_args('-y') { symlink.process { 2.times { ln 'stardot.rb' } } }

      expect(statuses.last).to eq :ok
    end

    it 'prompts to overwrite an existing symlink using cli flag "-i"' do
      expect(symlink).to receive :prompt

      with_cli_args('-i') do
        symlink.process { ln 'stardot.rb' }

        reply_with(one_of('y', 'n'), symlink) { ln 'stardot.rb' }
      end
    end

    it 'supports globbing the source location' do
      symlink.process { ln '*.txt' }

      [1, 2, 3].each { |i| expect(dest_symlink?("file-#{i}.txt")).to eq true }
    end

    it 'ignores "." and ".."' do
      %w[. ..]. each do |dot_dir|
        symlink.process { ln '.' }

        expect(dest_symlink?('.')).to eq false
      end
    end
  end
end
