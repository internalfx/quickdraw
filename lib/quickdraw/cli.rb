require 'thor'
#require 'yaml'
#YAML::ENGINE.yamler = 'syck' if defined? Syck
#require 'abbrev'
#require 'base64'
#require 'fileutils'
#require 'json'
require 'listen'
#require 'launchy'
require 'benchmark'

module Quickdraw
	class Cli < Thor
		include Thor::Actions

		BINARY_EXTENSIONS = %w(png gif jpg jpeg eot svg ttf woff otf swf ico)
		IGNORE = %w(config.yml)
		DEFAULT_WHITELIST = %w(layout/ assets/ config/ snippets/ templates/)
		TIMEFORMAT = "%H:%M:%S"

		desc "download FILE", "download the shops current theme assets"
		#method_option :quiet, :type => :boolean, :default => false
		def download(*keys)

			assets = keys.empty? ? Celluloid::Actor[:shopify_connector].get_asset_list : keys

			futures = []

			assets.each do |asset|
				futures << Celluloid::Actor[:shopify_connector].future.download_asset(asset)
			end

			futures.each do |future|
				say("Downloaded: #{future.value}", :green)
			end

			say("Done.", :green) unless options['quiet']
		end

		desc "watch", "compile then upload and delete individual theme assets as they change, use the --keep_files flag to disable remote file deletion"
		#method_option :quiet, :type => :boolean, :default => false
		#method_option :keep_files, :type => :boolean, :default => false
		def watch
			puts "Watching current folder: #{Dir.pwd}"
			listener = Listen.to(@path + '/src', :force_polling => true) do |modified, added, removed|
				modified.each do |filePath|
					filePath.slice!(Dir.pwd + "/")
					send_asset(filePath, options['quiet']) if local_assets_list.include?(filePath)
				end
				added.each do |filePath|
					filePath.slice!(Dir.pwd + "/")
					send_asset(filePath, options['quiet']) if local_assets_list.include?(filePath)
				end
				unless options['keep_files']
					removed.each do |filePath|
						filePath.slice!(Dir.pwd + "/")
						delete_asset(filePath, options['quiet']) if !local_assets_list.include?(filePath)
					end
				end
			end
			listener.start
			sleep
		rescue
			puts "exiting...."
		end

		private

		def download_asset(key)
			#notify_and_sleep("Approaching limit of API permits. Naptime until more permits become available!") if ShopifyTheme.needs_sleep?
			asset = ShopifyTheme.get_asset(key)
			if asset['value']
				# For CRLF line endings
				content = asset['value'].gsub("\r", "")
				format = "w"
			elsif asset['attachment']
				content = Base64.decode64(asset['attachment'])
				format = "w+b"
			end

			FileUtils.mkdir_p(File.dirname(key))
			File.open(key, format) {|f| f.write content} if content
		end

	end
end
