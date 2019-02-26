# frozen_string_literal: true

class Asdf < Stardot::Fragment
  def install(language, **opts)
    puts "asdf plugin-install #{language}"
    if opts[:versions]
      opts[:versions].each do |version|
        puts "|> asdf install #{language} #{version}"
      end
    end
  end
end


