#
# Monkey patch to allow authlogic's *_credentials cookies set the HttpOnly
# and Secure bits. Add this code to your #{Rails.root}/config/initializers dir.
#
#   @user_session = UserSession.new(params[:user_session])
#   @user_session.httponly = true
#
# or:
#
#   class UserSession < Authlogic::Session::Base
#     httponly true
#     secure true
#   end
#
# Add your votes to:
# https://github.com/binarylogic/authlogic/issuesearch#issue/210
#
# Thanks to boone@github:
# https://github.com/binarylogic/authlogic/issuesearch#issue/87
#

module Authlogic
  module Session
    module Cookies
      module Config
        # If the cookie should have the HttpOnly value set.
        #
        # * <tt>Default:</tt> false
        # * <tt>Accepts:</tt> Boolean
        def httponly(value = nil)
          rw_config(:httponly, value, false)
        end
        alias_method :httponly=, :httponly

        # If the cookie should have the Secure value set.
        #
        # * <tt>Default:</tt> false
        # * <tt>Accepts:</tt> Boolean
        def secure(value = nil)
          rw_config(:secure, value, false)
        end
        alias_method :secure=, :secure
      end

      module InstanceMethods
        # Is the cookie set using the HttpOnly value?
        def httponly
          return @httponly if defined?(@httponly)
          @httponly = self.class.httponly
        end

        # Accepts a boolean as a flag to set httponly or not.
        def httponly=(value)
          @httponly = value
        end

        # See httponly
        def httponly?
          httponly == true || httponly == "true" || httponly == "1"
        end

        # Is the cookie set using the Secure value?
        def secure
          return @secure if defined?(@secure)
          @secure = self.class.secure
        end

        # Accepts a boolean as a flag to set secure or not.
        def secure=(value)
          @secure = value
        end

        # See secure
        def secure?
          secure == true || secure == "true" || secure == "1"
        end

        private
          def save_cookie
            controller.cookies[cookie_key] = {
              :value => "#{record.persistence_token}::#{record.send(record.class.primary_key)}",
              :expires => remember_me_until,
              :domain => controller.cookie_domain,
              :httponly => httponly,
              :secure => secure
            }
          end
      end
    end
  end
end
