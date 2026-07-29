require "json"
require "fileutils"

module IssuePipeline
  # Reads and writes queue/queue.json, the gitignored work queue that tracks
  # issues moving through the fetch -> branch -> develop -> PR pipeline.
  module Queue
    PATH = File.expand_path("../../queue/queue.json", __dir__)

    module_function

    def load
      return [] unless File.exist?(PATH)

      JSON.parse(File.read(PATH))
    end

    def save(entries)
      FileUtils.mkdir_p(File.dirname(PATH))
      File.write(PATH, "#{JSON.pretty_generate(entries)}\n")
    end

    def find(number)
      load.find { |entry| entry["number"] == number }
    end

    def add(entry)
      entries = load
      return entries.find { |e| e["number"] == entry["number"] } if entries.any? { |e| e["number"] == entry["number"] }

      entries << entry
      save(entries)
      entry
    end

    def update(number, attrs)
      entries = load
      entry = entries.find { |e| e["number"] == number }
      raise ArgumentError, "no queue entry for issue ##{number}" unless entry

      entry.merge!(attrs)
      save(entries)
      entry
    end
  end
end
