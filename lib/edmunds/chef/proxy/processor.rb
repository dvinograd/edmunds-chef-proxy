require 'mixlib/authentication/http_authentication_request'
require 'mixlib/authentication/signatureverification'

module Edmunds
  module Chef
    module Processor

        def self.process_request(headers, http_method, request_url, settings)

          # request = Struct.new(:env, :method, :path)
          # @request = request.new(h, http_method, request_url)
          # p [:request, request]
          # @m = ::Mixlib::Authentication::HTTPAuthenticationRequest.new(request)

          user = headers["X-Ops-Userid"]
          p [:settings_user, user, settings["users"][user]]
          unless settings["users"] && settings["users"][user] && settings["users"][user]["groups"]
            return {:allow => false, :reason => "401"}
          end

          for group in settings["users"][user]["groups"]
            for rule in settings["groups"][group]["rules"]
              p [:match_rule, rule]
              if http_method =~ /#{rule["method"]}/ && request_url =~ /#{rule["url"]}/
                return {:allow => true}
              end
            end
          end

          return {:allow => false, :reason => "403"}

        end

    end
  end
end
