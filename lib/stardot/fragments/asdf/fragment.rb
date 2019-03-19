# frozen_string_literal: true

class Asdf < Stardot::Fragment
  def install(language, **opts)
    return error "plugin #{language} is not installed" unless plugin? language

    *versions = opts.fetch :versions, []

    tasks = versions.map do |version|
      installed = language_installed? language, version
      reinstall = installed && any_flag?('-y') || (interactive? &&
                  prompt("reinstall #{language} #{version}?",
                         %w[y n], selected: 'n') == 'y')

      # store async code in a proc so that we can prompt every version
      # synchronous first, then kick off installs later
      proc do
        if reinstall || !installed
          # FIXME: implement uninstall before reinstall
          persist_installation language, version

          if reinstall
            info "❖ reinstalled #{language} #{version}"
          else
            ok "❖ #{language} #{version}"
          end
        else
          info "❖ already installed #{language} #{version}"
        end
      end
    end

    # everything is confirmed, run stored procs (as)ynchronous
    tasks.each { |t| opts[:async] == false ? t.call : async(&t) }
  end

  private

  def persist_installation(language, version)
    `asdf install #{language} #{version} >/dev/null`
  end

  def language_installed?(name, version = nil)
    @language_cache ||= {}
    @language_cache[name] ||= `asdf list #{name}`.split("\n").map(&:strip).uniq
    @language_cache[name]&.include? version
  end

  def plugin?(name)
    @plugins ||= `asdf plugin-list`.to_s.split("\n")

    n = name.to_s.downcase
    @plugins.any? { |p| p == n }
  end
end
