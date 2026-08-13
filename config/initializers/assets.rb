# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# design_system_gem ships its Stimulus controllers (e.g. ui/sidebar's toggle
# behavior) under app/javascript rather than app/assets, so Rails::Engine's
# default asset paths don't pick it up automatically -- see config/importmap.rb.
Rails.application.config.assets.paths << DesignSystemGem::Engine.root.join("app/javascript")
