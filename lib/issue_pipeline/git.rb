require "open3"

module IssuePipeline
  # Thin wrapper around local git plumbing needed by the pipeline scripts.
  # Never force-pushes, deletes branches, or rewrites history.
  module Git
    class Error < StandardError; end
    class DirtyWorkingTree < Error; end

    module_function

    def run(*args)
      stdout, stderr, status = Open3.capture3("git", *args)
      raise Error, "git #{args.join(' ')} failed: #{stderr.strip}" unless status.success?

      stdout
    end

    def clean?
      run("status", "--porcelain").strip.empty?
    end

    def ensure_clean!
      return if clean?

      raise DirtyWorkingTree,
            "working tree has uncommitted changes -- commit, stash, or discard them before running the pipeline"
    end

    def checkout(branch)
      run("checkout", branch)
    end

    def pull(branch)
      run("pull", "origin", branch)
    end

    def local_branch_exists?(branch)
      _, _, status = Open3.capture3("git", "show-ref", "--verify", "--quiet", "refs/heads/#{branch}")
      status.success?
    end

    def remote_branch_exists?(branch)
      run("ls-remote", "--heads", "origin", branch).strip != ""
    end

    def create_branch(branch, from:)
      run("checkout", "-b", branch, from)
    end

    def push(branch)
      run("push", "-u", "origin", branch)
    end
  end
end
