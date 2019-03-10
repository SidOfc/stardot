# frozen_string_literal: true

class Asdf < Stardot::Fragment
  def install(language, **opts)
    opts[:versions]&.each do |version|
      async do
        slow_time = rand 1..6

        sleep slow_time
        ok "#{language} #{version}"
      end
    end
  end
end
