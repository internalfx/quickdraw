
require 'httparty'
require 'celluloid'

module Quickdraw
	class ShopifyConnectorPool
		include HTTParty
		include Celluloid

		def get(path, options = {})

			begin
				tries ||= 3

				response = HTTParty.get(path, options)

				if response.code == 429
					tries += 1
					puts "Too fast for Shopify!"
					raise "Slow down!"
				end

				if response.code != 200
					puts response.inspect
					raise "Request Failed"
				end

			rescue => e
				sleep 3
				retry unless (tries -= 1).zero?
			end

			return response
		end

	end

	Celluloid::Actor[:shopify_connector_pool] = ShopifyConnectorPool.pool(:size => 16)
end