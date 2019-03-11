# frozen_string_literal: true

class Symlink < Stardot::Fragment
  def ln(from, to = base, **opts)
    from = File.join base, from unless from.start_with? '/'
    to   = File.expand_path File.join(base, to) unless to.start_with? '/'
    to   = File.join(to, File.basename(from)) unless to =~ /\.\w+$/i || from !~ /\.\w+$/i
    dest_exists = File.symlink?(to) || Dir.exist?(to)

    if opts[:force] != true && dest_exists
      error "did not create #{sp(to)} because it already exists"
    elsif !File.exist? from
      error "could not create a symlink #{sp(to)} because #{sp(from)} does not exist"
    else
      FileUtils.remove_entry_secure to, force: true
      FileUtils.mkdir_p File.dirname(to) unless Dir.exist? File.dirname(to)
      File.symlink from, to
      ok "#{sp(from)} to #{sp(to)}"
    end
  end

  private

  def base(path = nil)
    @base = File.expand_path path if path
    @base || Dir.home
  end

  def sp(path)
    path.sub base, '~'
  end
end
