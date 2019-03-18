# frozen_string_literal: true

class Brew < Stardot::Fragment
  def install(package, *flags)
    perform      = !installed?(package)
    version_info = outdated_packages[package.to_s] unless perform

    if perform
      persist_installation(package, *flags)
      packages[package.to_s] = 'latest'
      ok "installed brew package: #{package}"
    elsif version_info && interactive?
      do_update = prompt("#{package} #{version_info[:current]} is outdated, update to version #{version_info[:latest]}?",
                         %w[y n], selected: 'y') == 'y'

      perform_update package if do_update
    else
      info "#{package} is already installed"
    end
  end

  private

  def perform_update(package)
    return
    `brew upgrade #{package}`
  end

  def persist_installation(package, *flags)
    `brew install #{package} #{flags.join(' ')}`
  end

  def outdated_packages
    @outdated_packages ||=
      JSON.parse(`brew outdated --json`)
          .each_with_object({}) do |pkg, h|
            h[pkg['name']] = {
              current: pkg['installed_versions'].last,
              latest: pkg['current_version']
            }
          end
  end

  def packages
    @packages ||=
      JSON.parse(`brew info --json=v1 --installed`)
          .each_with_object({}) do |pkg, h|
            h[pkg['name']] = pkg['installed'].last['version']
          end
  end

  def installed?(package)
    packages.key? package.to_s
  end
end
