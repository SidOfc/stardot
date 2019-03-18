# frozen_string_literal: true

class Asdf < Stardot::Fragment
  def install(language, **opts)
    return error "plugin #{language} is not installed" unless plugin? language

    *versions = opts.fetch :versions, []

    versions.each do |version|
      async do
        if language_installed? language, version
          info "already installed #{language} #{version}"
        else
          persist_installation language, version
          ok "❖ #{language} #{version}"
        end
      end
    end
  end

  private

  def persist_installation(language, version)
    `asdf install #{language} #{version} >/dev/null`
  end

  def language_installed?(name, version = nil)
    @language_cache ||= {}
    @language_cache[name] ||= `asdf list #{name}`.split("\n").uniq!

    @language_cache[name]&.include? version
  end

  def plugin?(name)
    @plugins ||= `asdf plugin-list`.to_s.split("\n")

    n = name.to_s.downcase
    @plugins.any? { |p| p == n }
  end
end
