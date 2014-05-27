require "edmunds/chef/proxy/version"
require "trollop"   # command-line option parser

require "em-proxy"  # proxy library

module Edmunds
  module Chef
    module Proxy

      def self.start

        # Parse options
        
        opts = Trollop::options do
           opt :quiet, "Use minimal output", :short => 'q'
           opt :verbose, "Output diagnostic info", :short => 'v'
           opt :chef, "Chef host:port to redirect to", :type => String
           opt :listen, "Local host:port to listen on", :type => String, :default => "0.0.0.0:8080"
           opt :config, "Configuration file to load", :type => String #, :default => "/etc/edmunds-chef-proxy/config.yml"
        end
        Trollop::die :config, "file must exist" unless File.exist?(opts[:config]) if opts[:config]
        Trollop::die :chef, "required option" if not opts[:chef]
        Trollop::die :chef, "invalid host:port" if opts[:chef].split(":").count != 2
        Trollop::die :listen, "invalid host:port" if opts[:listen].split(":").count != 2

        # Start proxy
        
        ::Proxy.start(:host => opts[:listen].split(":")[0], :port => opts[:listen].split(":")[1], :debug => opts[:verbose]) do |conn|
          conn.server :srv, :host => opts[:chef].split(":")[0], :port => Integer(opts[:chef].split(":")[1])

          # modify / process request stream
          conn.on_data do |data|
            p [:on_data, data]
            data
          end

          # modify / process response stream
          conn.on_response do |backend, resp|
            p [:on_response, backend, resp]
            resp
          end

          # termination logic
          conn.on_finish do |backend, name|
            p [:on_finish, name]

            # terminate connection (in duplex mode, you can terminate when prod is done)
            unbind if backend == :srv
          end
        end

      end

    end
  end
end
