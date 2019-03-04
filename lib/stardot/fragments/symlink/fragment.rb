# frozen_string_literal: true

class Symlink < Stardot::Fragment
  def ln(from, to = Dir.home)
    from = expand_path from
    to   = expand_path to

    ok "#{shorten_path(from)} to #{shorten_path(to)}"
  end

  private

  def expand_path(path)
    path.start_with?('/') ? path : File.join(Dir.home, path.delete('~'))
  end

  def shorten_path(path)
    path.sub Dir.home, '~'
  end
end
