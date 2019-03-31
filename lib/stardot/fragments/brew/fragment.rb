# frozen_string_literal: true

class Brew < Stardot::Fragment
  missing_binary :brew, :install_homebrew

  def install(package, *flags, **opts)
    version     = version_of package
    new_version = outdated_packages[package.to_s] if version

    tap opts[:tap] if opts[:tap] && untapped?(opts[:tap]) && (!version || new_version)

    if !version
      version = brew_info(package)[:version]
      packages[package.to_s] = version

      show_loader "installing #{package} #{version}" do
        perform_installation(package, *flags)
      end

      ok "installed brew package: #{package} #{[*flags, version].join(' ')}"
    elsif new_version
      update =
        any_flag?('-y') || interactive? &&
                           prompt("#{package} #{version} is outdated, update \
                                  to version #{new_version}?".gsub(/\s+/, ' '),
                                  %w[y n], selected: 'y') == 'y'

      return info "#{package} update to version #{new_version} skipped" \
        unless update

      show_loader "updating #{package} to version #{new_version}" do
        perform_update package
      end

      ok "#{package} updated to version #{new_version}"
    else
      info "#{package} #{version} is already installed and up to date"
    end
  end

  def tap(keg)
    if untapped? keg
      show_loader("tapping #{keg}") { perform_tap keg }
      ok "tapped #{keg}"
    else
      info "already tapped #{keg}"
    end
  end

  private

  def install_homebrew
    show_loader 'installing homebrew' do
      run_silent 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install'
    end
  end

  def perform_tap(keg)
    run_silent "brew tap #{keg}"
  end

  def perform_update(package)
    run_silent "brew upgrade #{package}"
  end

  def perform_installation(package, *flags)
    run_silent "brew install #{package} #{flags.join(' ')}"
  end

  def tapped
    @tapped ||= `brew tap`.split("\n").map(&:strip)
  end

  def untapped?(keg)
    !tapped.include?(keg)
  end

  def outdated_packages
    @outdated_packages ||=
      JSON.parse(`brew outdated --json`)
          .each_with_object({}) do |pkg, h|
            h[pkg['name']] = pkg['current_version']
          end
  end

  def brew_info(package)
    raw = JSON.parse(`brew info #{package} --json`.to_s).first

    { name: package,
      version: raw&.dig('versions', 'stable') }
  end

  def packages
    return @packages if @packages

    show_loader 'fetching package information', sticky: true do
      @packages =
        JSON.parse(`brew info --json=v1 --installed`)
            .each_with_object({}) do |pkg, h|
              h[pkg['name']] = pkg['installed'].last['version']
            end
    end

    @packages
  end

  def version_of(package)
    packages[package.to_s]
  end
end
