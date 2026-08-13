require "open3"

module IssuePipeline
  # Thin wrapper around local git plumbing needed by the pipeline scripts.
  # Never force-pushes, deletes branches, or rewrites history.
  module Git
    class Error < StandardError; end
    class DirtyWorkingTree < Error; end
    class UnsafeBranchName < Error; end

    # Branch names come from IssuePipeline::Slug (or "develop"), never from
    # raw external input, but every method here validates its branch
    # argument against this allowlist before shelling out -- both as
    # defense in depth and because Brakeman can't otherwise tell these
    # Open3 calls are exec'd as argv arrays, not shell strings.
    VALID_BRANCH = /\A[A-Za-z0-9][A-Za-z0-9._\/-]*\z/

    module_function

    def run(*args)
      stdout, stderr, status = Open3.capture3("git", *args)
      raise Error, "git #{args.join(' ')} failed: #{stderr.strip}" unless status.success?

      stdout
    end

    def assert_valid_branch!(branch)
      return branch if branch.is_a?(String) && VALID_BRANCH.match?(branch)

      raise UnsafeBranchName, "refusing to use unsafe branch name: #{branch.inspect}"
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
      run("checkout", assert_valid_branch!(branch))
    end

    def pull(branch)
      run("pull", remote_name, assert_valid_branch!(branch))
    end

    def local_branch_exists?(branch)
      _, _, status = Open3.capture3("git", "show-ref", "--verify", "--quiet", "refs/heads/#{assert_valid_branch!(branch)}")
      status.success?
    end

    def remote_branch_exists?(branch)
      run("ls-remote", "--heads", remote_name, assert_valid_branch!(branch)).strip != ""
    end

    def create_branch(branch, from:)
      run("checkout", "-b", assert_valid_branch!(branch), assert_valid_branch!(from))
    end

    def push(branch)
      run("push", "-u", remote_name, assert_valid_branch!(branch))
    end

    # rename_app.sh names the remote after the app (not "origin") when it
    # offers to create a GitHub repo, so we can't hardcode either name --
    # resolve it dynamically and cache the result for the process lifetime.
    def remote_name
      @remote_name ||= begin
        remotes = run("remote").split("\n").map(&:strip).reject(&:empty?)

        if remotes.include?("origin")
          "origin"
        elsif remotes.size == 1
          remotes.first
        else
          raise Error,
                "cannot determine git remote: found #{remotes.size} remote(s) (#{remotes.join(', ')}) " \
                "and none is named 'origin' -- rename the intended remote to 'origin' or remove the others"
        end
      end
    end
  end
end
