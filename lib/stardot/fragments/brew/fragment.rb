class Brew < Stardot::Fragment
  def install(package, **opts)
    puts "brew install #{package} with opts: #{opts}"
  end
end


