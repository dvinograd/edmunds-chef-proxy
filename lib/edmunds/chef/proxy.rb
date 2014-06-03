require "edmunds/chef/proxy/processor"
require "edmunds/chef/proxy/settings"
require "edmunds/chef/proxy/version"

require "trollop"   # command-line option parser
require "em-proxy"  # proxy library
require "http/parser"

module Edmunds
  module Chef
    module Proxy

      def self.start

        # Parse options
        
        $opts = Trollop::options do
           opt :quiet, "Use minimal output", :short => 'q', :default => false
           opt :verbose, "Output diagnostic info", :short => 'v', :default => false
           opt :chef, "Chef host:port to redirect to", :type => String, :short => 'c'
           opt :listen, "Local host:port to listen on", :type => String, :short => 'l', :default => "0.0.0.0:8080"
           opt :settings, "Configuration file to load (YAML format)", :type => String, :short => 's' #, :default => "/etc/edmunds-chef-proxy/settings.yml"
        end
        Trollop::die :settings, "file must exist" unless File.exist?($opts[:settings]) if $opts[:settings]
        Trollop::die :chef, "required option" if not $opts[:chef]
        Trollop::die :chef, "invalid host:port" if $opts[:chef].split(":").count != 2
        Trollop::die :listen, "invalid host:port" if $opts[:listen].split(":").count != 2

        # Load settings

        $settings = {}
        if $opts[:settings]
          $settings = Settings.load!($opts[:settings])
          p [:settings, $settings] if $opts[:verbose]
        end

        # Start proxy

        ::Proxy.start(:host => $opts[:listen].split(":")[0], :port => $opts[:listen].split(":")[1], :debug => $opts[:verbose]) do |conn|
          conn.server :srv, :host => $opts[:chef].split(":")[0], :port => Integer($opts[:chef].split(":")[1])

          @p = Http::Parser.new
          @client_request_body = ''
          @p.on_body = proc do |chunk|
            @client_request_body << chunk
          end
          @p.on_message_complete = proc do |env|
            @result = ::Edmunds::Chef::Processor.process_request(@p.headers, @p.http_method, @p.request_url, $settings)
            if @result[:allow]
              @chef_request = ::Edmunds::Chef::Processor.create_request(@p.headers, @p.http_method, @p.request_url, $opts[:chef], @client_request_body, $settings)
            end
          end

          conn.on_connect do |data,b|
            puts [:on_connect, data, b].inspect
          end

          # modify / process request stream
          conn.on_data do |data|
            # p [:on_data, data] if $opts[:verbose]
            @p << data
            if @result and @result[:allow]
              p [:chef_request, @chef_request]
              @chef_request
            else
              if not @result
                conn.send_data "HTTP/1.1 400 Bad Request\r\n\r\n"
                conn.close_connection true
              elsif @result[:reason] == "400"
                conn.send_data "HTTP/1.1 401 Unauthorized\r\n\r\n"
                conn.close_connection true
              elsif @result[:reason] == "403"
                conn.send_data "HTTP/1.1 403 Forbidden\r\n\r\n"
                conn.close_connection true
              else
                conn.send_data "HTTP/1.1 400 Bad Request\r\n\r\n"
                conn.close_connection true
              end
            end
          end

          # modify / process response stream
          conn.on_response do |backend, resp|
            # p [:on_response, backend, resp] if $opts[:verbose]
            resp if @result[:allow]
          end

          # termination logic
          conn.on_finish do |backend, name|
            # p [:on_finish, name] if $opts[:verbose]
            # terminate connection (in duplex mode, you can terminate when prod is done)
            unbind if backend == :srv
          end
        end

      end

    end
  end
end
