
require 'httparty'
require 'celluloid'
require 'pathname'
require 'filepath'

module Quickdraw
	class ShopifyConnector
		include Celluloid

		NOOPParser = Proc.new {|data, format| {} }
		BINARY_EXTENSIONS = %w(png gif jpg jpeg eot svg ttf woff otf swf ico)
		IGNORE = %w(config.yml)
		DEFAULT_WHITELIST = %w(layout/ assets/ config/ snippets/ templates/)
		TIMEFORMAT = "%H:%M:%S"

		def initialize
			@config = Quickdraw.config
			@auth = {:username => @config[:api_key], :password => @config[:password]}
		end

		def get_asset_list(options={})
			options.merge!({:parser => NOOPParser})
			response = Celluloid::Actor[:shopify_connector_pool].request(:get, "https://#{@config[:store]}/admin/themes/#{@config[:theme_id]}/assets.json", options)

			if JSON.parse(response.body)["assets"]
				return JSON.parse(response.body)["assets"].collect {|a| a['key'] }
			end

			return nil
		end

		def upload_asset(asset)
			time = Time.now
			data = {:key => asset.relative_to(Quickdraw.theme_dir).to_s}

			content = File.read(asset)
			if BINARY_EXTENSIONS.include?(File.extname(asset).gsub('.','')) || is_binary_data?(content)
				content = File.open(asset, "rb") { |io| io.read }
				data.merge!(:attachment => Base64.encode64(content))
			else
				data.merge!(:value => content)
			end

			data = {:body => {:asset => data}}

			response = Celluloid::Actor[:shopify_connector_pool].request(:put, "https://#{@config[:store]}/admin/themes/#{@config[:theme_id]}/assets.json", data)

			return [asset, response]
		end

		def download_asset(asset, options={})
			options.merge!({:query => {:asset => {:key => asset.relative_to(Quickdraw.theme_dir).to_s}}, :parser => NOOPParser})

			response = Celluloid::Actor[:shopify_connector_pool].request(:get, "https://#{@config[:store]}/admin/themes/#{@config[:theme_id]}/assets.json", options)

			# HTTParty json parsing is broken?
			data = response.code == 200 ? JSON.parse(response.body)["asset"] : {}
			data['response'] = response

			if data['value']
				# For CRLF line endings
				content = data['value'].gsub("\r", "")
				format = "w"
			elsif data['attachment']
				content = Base64.decode64(data['attachment'])
				format = "w+b"
			end

			FileUtils.mkdir_p(File.dirname(asset))
			File.open(asset, format) {|f| f.write content} if content

			return [asset, response]
		end

		def remove_asset(asset, options={})
			options.merge!({:body => {:asset => {:key => asset.relative_to(Quickdraw.theme_dir).to_s}}})

			response = Celluloid::Actor[:shopify_connector_pool].request(:delete, "https://#{@config[:store]}/admin/themes/#{@config[:theme_id]}/assets.json", options)

			return [asset, response]
		end

		def is_binary_data?(string)
			if string.respond_to?(:encoding)
				string.encoding == "US-ASCII"
			else
				( string.count( "^ -~", "^\r\n" ).fdiv(string.size) > 0.3 || string.index( "\x00" ) ) unless string.empty?
			end
		end

		def compile_asset(asset)
			if File.exists?(asset.to_s)
				target_asset = "theme/#{asset.relative_to(Quickdraw.src_dir).to_s.gsub('.erb', '')}"
				template = ERB.new(File.read(asset))
				File.write("#{target_asset}", template.result)
			end

			return [asset, nil]
		end

	end

	ShopifyConnector.supervise_as(:shopify_connector)
end