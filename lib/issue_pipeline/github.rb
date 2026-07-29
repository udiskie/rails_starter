require "json"
require "open3"

module IssuePipeline
  # Thin wrapper around the `gh` CLI. Every call shells out and raises on
  # non-zero exit so pipeline scripts fail loudly instead of silently
  # skipping a relabel or comment.
  module GitHub
    class Error < StandardError; end

    module_function

    def run(*args)
      stdout, stderr, status = Open3.capture3("gh", *args)
      raise Error, "gh #{args.join(' ')} failed: #{stderr.strip}" unless status.success?

      stdout
    end

    def open_issues_with_label(label)
      json = run("issue", "list", "--label", label, "--state", "open", "--json", "number,title", "--limit", "500")
      JSON.parse(json)
    end

    def issue(number)
      json = run("issue", "view", number.to_s, "--json", "number,title,url,body")
      JSON.parse(json)
    end

    def ensure_label(name, color: "ededed")
      existing = JSON.parse(run("label", "list", "--json", "name", "--limit", "500"))
      return if existing.any? { |l| l["name"] == name }

      run("label", "create", name, "--color", color)
    end

    def relabel(number, from:, to:)
      run("issue", "edit", number.to_s, "--remove-label", from, "--add-label", to)
    end

    def comment(number, body)
      run("issue", "comment", number.to_s, "--body", body)
    end

    def create_pr(base:, head:, title:, body:)
      run("pr", "create", "--base", base, "--head", head, "--title", title, "--body", body)
    end
  end
end
