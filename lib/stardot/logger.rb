# frozen_string_literal: true

module Stardot
  class Logger
    attr_reader :format, :file, :buffer

    def initialize(path, **opts)
      full_path = File.expand_path path
      log_dir   = File.dirname full_path

      FileUtils.mkdir_p log_dir unless Dir.exist? log_dir

      @format = opts.fetch :format, :yaml
      @file   = File.open full_path, 'a'
      @buffer = []
    end

    def append(entry)
      buffer << entry
    end

    def persist
      file.puts content
    end

    def to_s
      puts content
    end

    private

    def content
      case format
      when :yaml, :yml then buffer.to_yaml
      else buffer.to_json
      end
    end
  end
end
