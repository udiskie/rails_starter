module IssuePipeline
  module Slug
    module_function

    def for_title(title, max_length: 40)
      slug = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
      slug = slug[0, max_length].gsub(/-+$/, "")
      slug.empty? ? "untitled" : slug
    end

    def branch_name(number, title)
      "feature/issue-#{number}-#{for_title(title)}"
    end
  end
end
