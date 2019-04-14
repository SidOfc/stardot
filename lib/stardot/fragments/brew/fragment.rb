# frozen_string_literal: true

class Brew < Stardot::Fragment
  missing_binary :brew, :install_homebrew

  def install(package, *flags, **opts)
    version     = version_of package
    new_version = outdated_packages[package.to_s] if version

    tap opts[:tap] if tap_needed? opts[:tap], package

    return add package, flags unless version
    return update package if new_version

    info "#{package} #{version} is already installed and up to date"
  end

  def tap_needed?(keg, package)
    version     = version_of package
    new_version = outdated_packages[package.to_s] if version

    keg && untapped?(keg) && (!version || new_version)
  end

  def tap(keg)
    if untapped? keg
      load_while("tapping #{keg}") { perform_tap keg }
      ok "tapped #{keg}"
    else
      info "already tapped #{keg}"
    end
  end

  private

  def add(package, flags)
    version = brew_info(package)[:version]
    packages[package.to_s] = version

    load_while "installing #{package} #{version}" do
      perform_installation(package, *flags)
    end

    ok "installed brew package: #{package} #{[version, *flags].join(' ')}"
  end

  def update(package)
    version     = version_of package
    new_version = outdated_packages[package.to_s]
    update =
      any_flag?('-y') || interactive? &&
                         prompt("#{package} #{version} is outdated, update \
                                to version #{new_version}?".gsub(/\s+/, ' '),
                                %w[y n], selected: 'y') == 'y'

    return warn "#{package} update to version #{new_version} skipped" \
      unless update

    load_while "updating #{package} to version #{new_version}" do
      perform_update package
    end

    ok "#{package} updated to version #{new_version}"
  end

  def install_homebrew
    load_while 'installing homebrew' do
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
    @tapped ||= bash('brew tap').split("\n").map(&:strip)
  end

  def untapped?(keg)
    !tapped.include?(keg)
  end

  def outdated_packages
    @outdated_packages ||=
      JSON.parse(bash('brew outdated --json'))
          .each_with_object({}) do |pkg, h|
            h[pkg['name']] = pkg['current_version']
          end
  end

  def brew_info(package)
    raw = JSON.parse(bash("brew info #{package} --json").to_s).first

    { name: package,
      version: raw&.dig('versions', 'stable') }
  end

  def packages
    return @packages if @packages

    load_while 'retrieving package information', sticky: true do
      @packages =
        JSON.parse(bash('brew info --json=v1 --installed'))
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
