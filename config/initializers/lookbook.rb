if Rails.env.development?
  Rails.application.config.lookbook.preview_paths << DesignSystemGem::Engine.root.join("test/components/previews").to_s
end
