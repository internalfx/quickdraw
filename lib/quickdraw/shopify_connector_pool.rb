
require 'httparty'
require 'celluloid'
require 'filepath'

module Quickdraw
	class ShopifyConnectorPool
		include HTTParty
		include Celluloid

		def initialize
			@config = Quickdraw.config
			@auth = {:username => @config[:api_key], :password => @config[:password]}
		end

		def request(call_type, path, options)
			options.merge!({:basic_auth => @auth})

			begin
				tries ||= 3

				response = HTTParty.send(call_type, path, options)

				if response.code == 429
					tries += 1
					puts "Too fast for Shopify! Retrying..."
					raise "Slow down!"
				end

				if response.code == 403
					tries == 0
					raise "Forbidden"
				end

				if response.code != 200
					puts response.inspect
					raise "Request Failed"
				end

			rescue => e
				tries -= 1
				if tries > 0
					sleep 1
					retry
				end
			end

			return response
		end

	end

	Celluloid::Actor[:shopify_connector_pool] = ShopifyConnectorPool.pool(:size => 24)
end