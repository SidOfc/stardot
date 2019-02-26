# frozen_string_literal: true

class Commands < Stardot::Fragment
  def run(command)
    puts "running: #{command}"
  end
end
