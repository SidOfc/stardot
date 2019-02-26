# frozen_string_literal: true

class Symlink < Stardot::Fragment
  def ln(from, to = Dir.home)
    from = expand_path from
    to   = expand_path to

    puts "symlink: #{from} ~> #{to}"
  end

  private

  def expand_path(path)
    path.start_with?('/') ? path : File.join(Dir.home, path.gsub('~', ''))
  end
end
