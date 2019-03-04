# frozen_string_literal: true

class Brew < Stardot::Fragment
  def install(package, **opts)
    ok "#{package}, options: #{opts}"
  end
end
