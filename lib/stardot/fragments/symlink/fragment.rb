# frozen_string_literal: true

class Symlink < Stardot::Fragment
  def ln(from = src, to = dest, **opts)
    from = expand_from from

    return from.each { |f| ln(f, to, **opts) } if from.is_a? Array
    return if from.end_with? '/.', '/..'

    if !File.exist?(from)
      error "could not create a symlink because #{sp(from)} does not exist"
    else
      add_symlink from, to, opts
    end
  end

  def add_symlink(from, to, opts)
    to = expand_to to, from

    if symlink? to, opts
      persist from, to
      ok "#{sp(from)} to #{sp(to)}"
    else
      info "did not create #{sp(to)} because it already exists"
    end
  end

  def symlink?(to, opts)
    opts.fetch(:force, any_flag?('-y') || !File.exist?(to)) ||
      interactive? && prompt("overwrite #{sp(to)}?",
                             %w[y n], selected: 'n') == 'y'
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
    glob = Dir.glob from

    return from unless glob.any?
    return glob.first if glob.count == 1

    glob
  end

  # FIXME: clean this mess up
  def expand_to(to, from)
    no_to = to == dest # not passed, so defaulted to dest
    to    = File.join dest, to unless to.start_with? '/'
    to    = to.gsub %r{[\/]+\z}, ''

    if no_to || !File.directory?(from) && (file_to_dir_symlink?(from, to) ||
                                           dir_to_dir_symlink?(from, to))
      to = File.join to, File.basename(from)
    end

    to
  end

  def file_to_dir_symlink?(from, to)
    ext?(from) && !ext?(to)
  end

  def dir_to_dir_symlink?(from, to)
    !ext?(from) && Dir.exist?(to)
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
