# frozen_string_literal: true

RSpec.describe Stardot do
  ROOT = File.join __dir__, 'files'
  def fragment(&block)
    Stardot::Fragment.new(silent: true, &block).process
  end

  def as_plugin(name, &block)
    fragment { send(name, &block) }
  end

  describe 'Symlink#ln' do
    SYMLINK = File.join ROOT, 'symlink'

    before :each do
      FileUtils.mkdir_p SYMLINK
    end

    after :each do
      FileUtils.rm_rf SYMLINK
    end

    it 'can create a symlink' do
      as_plugin :symlink do
        base SYMLINK

        ln File.join(ROOT, 'stardot.rb'), File.join(SYMLINK, 'stardot.rb')
      end

      expect(File.symlink?(File.join(SYMLINK, 'stardot.rb'))).to be true
    end

    it 'errors out when source file does not exist' do
      as_plugin :symlink do
        base SYMLINK

        ln '_', File.join(SYMLINK, 'stardot.rb')
      end

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end

    it 'does not overwrite existing symlinks by default' do
      as_plugin :symlink do
        base SYMLINK

        ln File.join(ROOT, 'stardot.rb'), File.join(SYMLINK, 'stardot.rb')
        ln File.join(ROOT, 'stardot.rb'), File.join(SYMLINK, 'stardot.rb')
      end

      expect(Stardot.logger.entries.last[:status]).to eq :error
    end

    it 'can force overwrite an existing symlink' do
      as_plugin :symlink do
        base SYMLINK

        ln File.join(ROOT, 'stardot.rb'), File.join(SYMLINK, 'stardot.rb')
        ln File.join(ROOT, 'stardot.rb'), File.join(SYMLINK, 'stardot.rb'),
           force: true
      end

      expect(Stardot.logger.entries.last[:status]).to eq :ok
    end
  end
end
