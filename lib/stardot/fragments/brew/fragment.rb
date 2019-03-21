# frozen_string_literal: true

class Brew < Stardot::Fragment
  def install(package, *flags, **opts)
    version     = version_of package
    new_version = outdated_packages[package.to_s] if version

    if !version
      info_version = brew_info(package)[:version]
      packages[package.to_s] = 'latest'

      show_loader "installing #{package} #{info_version}" do
        persist_installation(package, *flags)
      end

      ok "installed brew package: #{package} #{info_version}"
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

  private

  def perform_update(package)
    `brew upgrade #{package} >/dev/null 2>&1`
  end

  def persist_installation(package, *flags)
    `brew install #{package} #{flags.join(' ')} >/dev/null 2>&1`
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
      version: raw&.dig('versions', 'stable') || 'unknown' }
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
