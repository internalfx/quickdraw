
require 'httparty'
require 'celluloid'
require 'pathname'

module Quickdraw
	class ShopifyConnector
		include Celluloid

		NOOPParser = Proc.new {|data, format| {} }

		def initialize
			@config = Quickdraw.config
			@auth = {:username => @config[:username], :password => @config[:password]}
		end

		def get(path, options={})
			options.merge!({:basic_auth => @auth})

			response = Celluloid::Actor[:shopify_connector_pool].get(path, options)

			return response
		end

		def get_asset_list(options={})
			options.merge!({:parser => NOOPParser})
			response = get("https://#{@config[:store]}/admin/themes/#{@config[:theme_id]}/assets.json", options)

			if JSON.parse(response.body)["assets"]
				return JSON.parse(response.body)["assets"].collect {|a| a['key'] }
			end

			return nil
		end

		def download_asset(assetpath, options={})
			options.merge!({:query => {:asset => {:key => assetpath}}, :parser => NOOPParser})

			response = get("https://#{@config[:store]}/admin/themes/#{@config[:theme_id]}/assets.json", options)

			# HTTParty json parsing is broken?
			asset = response.code == 200 ? JSON.parse(response.body)["asset"] : {}
			asset['response'] = response

			if asset['value']
				# For CRLF line endings
				content = asset['value'].gsub("\r", "")
				format = "w"
			elsif asset['attachment']
				content = Base64.decode64(asset['attachment'])
				format = "w+b"
			end

			save_path = "theme/"+assetpath

			FileUtils.mkdir_p(File.dirname(save_path))
			File.open(save_path, format) {|f| f.write content} if content

			return assetpath
		end
	end

	ShopifyConnector.supervise_as(:shopify_connector)
end