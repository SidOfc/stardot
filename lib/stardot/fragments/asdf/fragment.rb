# frozen_string_literal: true

class Asdf < Stardot::Fragment
  def install(language, **opts)
    opts[:versions]&.each do |version|
      ok "#{language} #{version}"
    end
  end
end
