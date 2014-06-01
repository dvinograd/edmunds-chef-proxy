require 'mixlib/authentication/http_authentication_request'
require 'mixlib/authentication/signatureverification'

module Edmunds
  module Chef
    module Processor

      def self.process_request(data, settings)
        @m = ::Mixlib::Authentication::HTTPAuthenticationRequest.new(data)
        if @m.user_id() == "dvinogradov"
          data
        else
          nil
        end
      end

    end
  end
end
