# frozen_string_literal: true

class Symlink < Stardot::Fragment
  def ln(from = src, to = dest, **opts)
    from = expand_from from
    to   = expand_to to, from
    allowed = opts.fetch :force, any_flag?('-y') || !File.exist?(to)
    allowed = prompt("overwrite: #{sp(to)}", %w[y n], selected: 'n') == 'y' \
      if !allowed && interactive?

    if !File.exist?(from)
      error "could not create a symlink because #{sp(from)} does not exist"
    elsif allowed
      persist from, to
      ok "#{sp(from)} to #{sp(to)}"
    else
      error "did not create #{sp(to)} because it already exists"
    end
  end

  def dest(path = nil)
    @dest = File.expand_path path if path
    @dest || Dir.home
  end

  def src(path = nil)
    @src = File.expand_path path if path
    @src || Dir.home
  end

  private

  def expand_from(from)
    from = File.join src, from unless from.start_with? '/'
    from
  end

  def expand_to(to, from)
    to = File.join dest, to unless to.start_with? '/'
    to = to.gsub %r{[\/]+\z}, ''

    if (ext?(from) && !ext?(to)) || (!ext?(from) && Dir.exist?(to))
      to = File.join to, File.basename(from)
    end

    to
  end

  def ext?(path)
    path =~ %r{\.[^\/.]+\z}
  end

  def persist(from, to)
    FileUtils.remove_entry_secure to, force: true
    FileUtils.mkdir_p File.dirname(to) unless File.exist? File.dirname(to)

    File.symlink from, to
  end

  def sp(path)
    parts = path.sub(Dir.home, '~').split(%r{[\/]}i)
    File.join(*parts[0..-2].map(&method(:short_dirname)), parts.last)
  end

  def short_dirname(dir)
    return dir[0..1] if dir.start_with? '.'

    dir[0]
  end
end
