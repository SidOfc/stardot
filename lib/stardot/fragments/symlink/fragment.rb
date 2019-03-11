# frozen_string_literal: true

class Symlink < Stardot::Fragment
  def ln(from, to = base, **opts)
    from = File.expand_path from
    to   = File.expand_path to
    dest_exists = File.symlink? to

    if opts[:force] != true && dest_exists
      error "did not create #{sp(to)} because it already exists"
    elsif !File.exist? from
      error "could not create a symlink #{sp(to)} because #{sp(from)} does not exist"
    else
      File.unlink to if dest_exists
      File.symlink from, to
      ok "#{sp(from)} to #{sp(to)}"
    end
  end

  private

  def base(path = nil)
    @base = path if path
    @base || Dir.home
  end

  def sp(path)
    path.sub base, '~'
  end
end
