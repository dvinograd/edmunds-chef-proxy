require 'mixlib/authentication/http_authentication_request'
require 'mixlib/authentication/signatureverification'

module Edmunds
  module Chef
    module Processor

        def self.process_request(h, p, settings)

          response = Hash.new
          # request = Struct.new(:env, :method, :path)
          # @request = request.new(h, p.http_method, p.request_url)
          # p [:request, request]
          # @m = ::Mixlib::Authentication::HTTPAuthenticationRequest.new(request)

          if p.request_url =~ /role/
            response[:allow] = true
          else
            response[:allow] = false
            response[:reason] = "403"
          end

          return response

        end

    end
  end
end
