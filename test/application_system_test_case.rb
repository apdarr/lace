require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Global OmniAuth test configuration
  OmniAuth.config.test_mode = true

  # Set the default path for OmniAuth in test mode
  OmniAuth.config.path_prefix = "/auth"
end
