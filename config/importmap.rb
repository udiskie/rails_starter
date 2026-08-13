# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# design_system_gem's ui/sidebar renders its toggle/open/close behavior through
# a Stimulus controller (CSP-safe, no inline onclick/<script>) rather than pinning
# it itself -- the gem's own config/ isn't packaged, so the host app pins it here.
# Requires design_system_gem's app/javascript dir on config.assets.paths (see
# config/initializers/assets.rb) so Propshaft can resolve the relative path below.
pin "controllers/sidebar_controller", to: "controllers/sidebar_controller.js"
