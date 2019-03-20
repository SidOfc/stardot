# frozen_string_literal: true

class Brew < Stardot::Fragment
  def install(package, *flags, **opts)
    version     = version_of package
    new_version = outdated_packages[package.to_s] if version

    if !version
      info_version = brew_info(package)[:version]
      packages[package.to_s] = 'latest'

      async { persist_installation(package, *flags) }
      wait_for_async_tasks progress: {
        text: "installing #{package} #{info_version}"
      }

      ok "installed brew package: #{package} #{info_version}"
    elsif new_version && interactive?
      update = prompt("#{package} #{version} is outdated, update \
                      to version #{new_version}?".gsub(/\s+/, ' '),
                      %w[y n], selected: 'y') == 'y'

      return info "#{package} update to version #{new_version} skipped" \
        unless update

      async { perform_update package }
      wait_for_async_tasks progress: {
        text: "updating #{package} to version #{new_version}"
      }


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

    async do
      @packages =
        JSON.parse(`brew info --json=v1 --installed`)
            .each_with_object({}) do |pkg, h|
              h[pkg['name']] = pkg['installed'].last['version']
            end
    end

    wait_for_async_tasks progress: {
      text: 'fetching package information',
      sticky: true
    }

    @packages
  end

  def version_of(package)
    packages[package.to_s]
  end
end
