ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Silence Hashie object_id redefinition warning in Ruby 3.4+
# Must run before bundler/setup loads gems
if RUBY_VERSION >= "3.4"
  module Warning
    class << self
      alias_method :_original_warn, :warn

      def warn(message)
        if message.include?("hashie") && message.include?("object_id") && message.include?("redefining")
          return # Suppress this specific warning
        end
        _original_warn(message)
      end
    end
  end
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
