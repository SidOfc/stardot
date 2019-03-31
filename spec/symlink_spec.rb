# frozen_string_literal: true

RSpec.describe 'Symlink' do
  def dest_symlink?(*loc)
    File.symlink? File.join(symlink.dest, *loc)
  end

  let :symlink do
    symlink = as_plugin :symlink
    symlink.src  Helpers::ROOT_DIR
    symlink.dest File.join(Helpers::ROOT_DIR, 'symlink')
    symlink
  end

  before(:each) { FileUtils.mkdir_p symlink.dest }
  after(:each) { FileUtils.rm_rf symlink.dest }

  describe '#ln' do
    it 'creates a file symlink' do
      symlink.ln 'stardot.rb', 'stardot.rb'

      expect(dest_symlink?('stardot.rb')).to eq true
    end

    it 'uses source filename when destination is absent' do
      symlink.ln 'stardot.rb'

      expect(dest_symlink?('stardot.rb')).to eq true
    end

    it 'creates a directory symlink' do
      symlink.ln 'folder/', 'folder/'

      expect(dest_symlink?('folder')).to eq true
    end

    it 'uses source dirname when destination is absent' do
      symlink.ln 'folder/'

      expect(dest_symlink?('folder')).to eq true
    end

    it 'errors when source location does not exist' do
      symlink.ln '_', 'stardot.rb'

      expect(statuses.last).to eq :error
    end

    it 'does not overwrite an existing symlink' do
      2.times { symlink.ln 'stardot.rb' }

      expect(statuses.last).to eq :info
    end

    it 'overwrites an existing symlink using force: true' do
      symlink.ln 'stardot.rb'
      symlink.ln 'stardot.rb', force: true

      expect(statuses.last).to eq :ok
    end

    it 'overwrites an existing symlink using cli flag "-y"' do
      with_cli_args('-y') { 2.times { symlink.ln 'stardot.rb' } }

      expect(statuses.last).to eq :ok
    end

    it 'prompts to overwrite an existing symlink using cli flag "-i"' do
      expect(symlink).to receive :prompt

      with_cli_args('-i') do
        symlink.ln 'stardot.rb'

        reply_with(one_of('y', 'n'), symlink) { ln 'stardot.rb' }
      end
    end

    it 'supports globbing the source location' do
      symlink.ln '*.txt'

      [1, 2, 3].each { |i| expect(dest_symlink?("file-#{i}.txt")).to eq true }
    end

    it 'ignores "." and ".."' do
      %w[. ..]. each do |dot_dir|
        symlink.ln dot_dir

        expect(dest_symlink?(dot_dir)).to eq false
      end
    end
  end
end
