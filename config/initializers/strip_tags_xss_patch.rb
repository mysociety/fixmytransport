# A patch for CVE-2012-3465
# https://groups.google.com/forum/#!msg/rubyonrails-security/FgVEtBajcTY/tYLS1JJTu38J
module ActionView
  module Helpers
    module SanitizeHelper
      def strip_tags(html)
         self.class.full_sanitizer.sanitize(html)
      end
    end
  end
end