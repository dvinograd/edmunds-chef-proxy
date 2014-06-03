require 'mixlib/authentication/http_authentication_request'
require 'mixlib/authentication/signatureverification'
require 'mixlib/authentication/signedheaderauth'
require 'openssl'

module Edmunds
  module Chef
    module Processor

        def self.process_request(headers, http_method, request_path, settings)

          # request = Struct.new(:env, :method, :path)
          # @request = request.new(h, http_method, request_path)
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
              if http_method =~ /#{rule["method"]}/ && request_path =~ /#{rule["url"]}/
                return {:allow => true}
              end
            end
          end

          return {:allow => false, :reason => "403"}

        end

        def self.create_request(headers, http_method, request_path, request_host, request_body, settings)

          if http_method == "GET"
            client = settings["keys"]["readonly_client"]
            client_key_file = settings["keys"]["readonly_key"]
          else
            client = settings["keys"]["readwrite_client"]
            client_key_file = settings["keys"]["readwrite_key"]
          end
          client_key = OpenSSL::PKey::RSA.new( File.read(client_key_file) )
          signed_headers = Mixlib::Authentication::SignedHeaderAuth.signing_object(
            :http_method => http_method,
            :body        => request_body || '',
            :host        => request_host,
            :path        => request_path,
            :timestamp   => Time.now.utc.iso8601,
            :user_id     => client,
            :file        => '',
          ).sign(client_key)

          # p [:signed_headers, signed_headers]
          signed_headers_str = "#{http_method} #{request_path} HTTP/1.1\r\n"
          signed_headers_str << "Connection: close\r\nUser-Agent: edmunds-chef-proxy\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: application/json\r\n"
          ["X-Ops-Sign", "X-Ops-Userid", "X-Ops-Content-Hash", "X-Ops-Timestamp", "X-Remote-Request-Id"].each do |key|
            signed_headers_str << "#{key}: #{signed_headers[key]}\r\n" if signed_headers[key]
          end
          signed_headers_str << "Host: #{request_host}\r\n"
          signed_headers_str << "Content-Type: application/json\r\n" if request_body
          signed_headers_str << "Content-Length: #{request_body.length}\r\n" if request_body
          (1..9).to_a.each do |key|
            key = "X-Ops-Authorization-#{key}"
            signed_headers_str << "#{key}: #{signed_headers[key]}\r\n" if signed_headers[key]
          end
          signed_headers_str << "\r\n"
          # p [:signed_headers_str, signed_headers_str]
          return signed_headers_str + request_body
        end

    end
  end
end
