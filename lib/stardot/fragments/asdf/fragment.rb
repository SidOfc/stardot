# frozen_string_literal: true

class Asdf < Stardot::Fragment
  def install(language, **opts)
    unless plugin? language
      return error "no such plugin: #{language}" unless plugin_exists? language

      show_loader "installing plugin #{language}" do
        perform_language_installation language
      end
    end

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
          perform_uninstall language, version if reinstall
          perform_installation language, version

          if reinstall
            info "❖ reinstalled #{language} #{version}"
          else
            ok "❖ #{language} #{version}"
          end
        else
          info "❖ #{language} #{version} is already installed"
        end
      end
    end

    # everything is confirmed, run stored procs (as)ynchronous
    tasks.each { |t| opts[:async] == false ? t.call : async(&t) }
  end

  private

  def perform_language_installation(language)
    run_silent "asdf plugin-add #{language}"
  end

  def perform_uninstall(language, version)
    run_silent "asdf uninstall #{language} #{version}"
  end

  def perform_installation(language, version)
    run_silent "asdf install #{language} #{version}"
  end

  def perform_uninstall(language, version)
    run_silent "asdf uninstall #{language} #{version}"
  end

  def language_installed?(name, version = nil)
    @language_cache ||= {}
    @language_cache[name] ||= `asdf list #{name}`.split("\n").map(&:strip).uniq
    @language_cache[name]&.include? version
  end

  def plugin_exists?(name)
    @existing_plugins ||= `asdf plugin-list-all`.to_s.split("\n").map { |ln| ln.split(/\s+/).first }

    n = name.to_s.downcase
    @existing_plugins.any? { |p| p == n }
  end

  def plugin?(name)
    @plugins ||= `asdf plugin-list`.to_s.split("\n")

    n = name.to_s.downcase
    @plugins.any? { |p| p == n }
  end
end
