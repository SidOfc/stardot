# frozen_string_literal: true

module Stardot
  class Logger
    attr_reader :format, :file, :buffer, :path, :dir

    def initialize(file_path, **opts)
      @path   = File.expand_path file_path
      @dir    = File.dirname @path
      @format = opts.fetch :format, :yaml
      @buffer = []
    end

    def append(entry)
      buffer << entry
    end

    def persist
      @file ||= begin
                  FileUtils.mkdir_p dir unless Dir.exist? dir
                  File.open path, 'a'
                end

      @file.puts content
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
