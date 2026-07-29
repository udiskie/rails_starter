require_relative "issue_pipeline/queue"
require_relative "issue_pipeline/github"
require_relative "issue_pipeline/git"
require_relative "issue_pipeline/slug"

module IssuePipeline
  INTEGRATION_BRANCH = "develop".freeze

  LABELS = {
    refined: "refined",
    queued: "queued",
    in_progress: "in-progress",
    in_review: "in-review",
    blocked: "blocked"
  }.freeze

  PROMPTS_DIR = File.expand_path("../prompts", __dir__)
end
