# frozen_string_literal: true

module Stardot
  class Logger
    attr_reader :format, :file, :entries, :path

    def initialize(file_path = "log/stardot.#{Time.now.to_i}.log", **opts)
      @path    = File.expand_path file_path
      @format  = opts.fetch :format, :yaml
      @entries = []
    end

    def append(entry)
      entries << entry
    end

    def persist(location = @path)
      dir = File.dirname location
      @file ||= begin
                  FileUtils.mkdir_p dir unless Dir.exist? dir
                  File.open location, 'a'
                end

      @file.puts content
    end

    def to_s
      puts content
    end

    def clear
      @entries.clear
    end

    private

    def content
      case format
      when :yaml, :yml then entries.to_yaml
      else entries.to_json
      end
    end
  end
end
