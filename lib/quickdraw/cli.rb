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
require 'pathname'
require 'filepath'

module Quickdraw
	class Cli < Thor
		include Thor::Actions

		BINARY_EXTENSIONS = %w(png gif jpg jpeg eot svg ttf woff otf swf ico)
		IGNORE = %w(config.yml)
		DEFAULT_WHITELIST = %w(layout/ assets/ config/ snippets/ templates/)
		TIMEFORMAT = "%H:%M:%S"

		desc "configure", "generate a config file for the store to connect to"
		def configure
			config = {
				:api_key => ask("API Key?"),
				:password => ask("Password?"),
				:store => ask("Store domain (ex. 'example.myshopify.com')?"),
				:theme_id => ask("Theme ID")
			}
			create_file('config.yml', config.to_yaml)
			empty_directory('src')
			empty_directory('theme')
		end

		desc "upload FILES", "upload all theme assets to shop"
		def upload(filter=nil)

			if filter
				assets = (FilePath.getwd / 'theme').files(true).select{ |i|
					i.relative_to(Quickdraw.theme_dir).to_s[/^#{filter.gsub(/[^a-z0-9A-Z\/]/, '')}/]
				}
			else
				assets = (FilePath.getwd / 'theme').files(true)
			end

			futures = []
			assets.each do |asset|
				futures << Celluloid::Actor[:shopify_connector].future.upload_asset(asset)
			end
			futures.each do |future|
				asset, response = future.value
				if response.success?
					say("Uploaded: #{asset.relative_to(Quickdraw.getwd)}", :green)
				else
					say("[" + Time.now.strftime(TIMEFORMAT) + "] Error: Could not upload #{asset.relative_to(Quickdraw.getwd)}. #{errors_from_response(response)}\n", :red)
				end
			end

			say("Done.", :green)
		end

		desc "download FILES", "download the shops current theme assets"
		def download(filter=nil)
			asset_list = Celluloid::Actor[:shopify_connector].get_asset_list

			if filter
				assets = asset_list.select{ |i| i[/^#{filter.gsub(/[^a-z0-9A-Z\/]/, '')}/] }.map{|a| FilePath.getwd / 'theme' / a }
			else
				assets = asset_list.map{|a| FilePath.getwd / 'theme' / a }
			end

			futures = []
			assets.each do |asset|
				futures << Celluloid::Actor[:shopify_connector].future.download_asset(asset)
			end
			futures.each do |future|
				asset, response = future.value
				if response.success?
					say("Downloaded: #{asset.relative_to(Quickdraw.getwd)}", :green)
				else
					say("[" + Time.now.strftime(TIMEFORMAT) + "] Error: Could not download #{asset.relative_to(Quickdraw.getwd)}. #{errors_from_response(response)}\n", :red)
				end
			end
			say("Done.", :green)
		end

		desc "replace FILES", "completely replace shop theme assets with local theme assets"
		def replace(filter=nil)
			say("Are you sure you want to completely replace your shop theme assets? This is not undoable.", :yellow)
			if ask("Continue? (y/n): ") == "y"
				# only delete files on remote that are not present locally
				# files present on remote and present locally get overridden anyway
				asset_list = Celluloid::Actor[:shopify_connector].get_asset_list

				if filter
					remote_assets = asset_list.select{ |i| i[/^#{filter.gsub(/[^a-z0-9A-Z\/]/, '')}/] }.map{|a| (FilePath.getwd / 'theme' / a) }
				else
					remote_assets = asset_list.map{|a| (FilePath.getwd / 'theme' / a) }
				end

				if filter
					local_assets = (FilePath.getwd / 'theme').files(true).select{ |i| i.relative_to(Quickdraw.theme_dir).to_s[/^#{filter.gsub(/[^a-z0-9A-Z\/]/, '')}/] }
				else
					local_assets = (FilePath.getwd / 'theme').files(true)
				end

				remote_only_assets = remote_assets.to_a.map{|p| p.to_s} - local_assets.to_a.map{|p| p.to_s}

				futures = []
				remote_only_assets.each do |asset|
					futures << Celluloid::Actor[:shopify_connector].future.remove_asset(asset.as_path)
				end
				local_assets.each do |asset|
					futures << Celluloid::Actor[:shopify_connector].future.upload_asset(asset)
				end
				futures.each do |future|
					asset, response = future.value
					if response.success?
						if response.request.http_method.to_s == "Net::HTTP::Put"
							say("Uploaded: #{asset.relative_to(Quickdraw.getwd)}", :green)
						else
							say("Removed: #{asset.relative_to(Quickdraw.getwd)}", :green)
						end
					else
						say("[" + Time.now.strftime(TIMEFORMAT) + "] Error: Could not download #{asset.relative_to(Quickdraw.getwd)}. #{errors_from_response(response)}\n", :red)
					end
				end
				say("Done.", :green) unless options['quiet']
			end
		end

		desc "remove FILES", "remove theme asset"
		def remove(filter=nil)
			asset_list = Celluloid::Actor[:shopify_connector].get_asset_list

			if filter
				assets = asset_list.select{ |i| i[/^#{filter.gsub(/[^a-z0-9A-Z\/]/, '')}/] }.map{|a| FilePath.getwd / 'theme' / a }
			else
				assets = asset_list.map{|a| FilePath.getwd / 'theme' / a }
			end

			futures = []
			assets.each do |asset|
				futures << Celluloid::Actor[:shopify_connector].future.remove_asset(asset)
			end
			futures.each do |future|
				asset, response = future.value
				if response.success?
					say("Deleted: #{asset.relative_to(Quickdraw.getwd)}", :green)
				else
					say("[" + Time.now.strftime(TIMEFORMAT) + "] Error: Could not remove #{asset.relative_to(Quickdraw.getwd)}. #{errors_from_response(response)}\n", :red)
				end
			end
			say("Done.", :green) unless options['quiet']
		end

		desc "watch", "compile then upload or delete individual theme assets as they change."
		def watch
			puts "Watching current folder: #{Dir.pwd}"

			futures = []

			listener = Listen.to((Quickdraw.getwd/'theme').to_s, (Quickdraw.getwd/'src').to_s, :force_polling => true, :latency => 0.2 ) do |modified, added, removed|
				modified.each do |asset|
					asset = asset.as_path
					say("MODIFIED: #{asset.relative_to(Quickdraw.getwd)}", :green)
					if theme_file?(asset)
						futures << Celluloid::Actor[:shopify_connector].future.upload_asset(asset)
					elsif src_file?(asset)
						futures << Celluloid::Actor[:shopify_connector].future.compile_asset(asset)
					end
				end
				added.each do |asset|
					asset = asset.as_path
					say("ADDED: #{asset}", :green)
					if theme_file?(asset)
						futures << Celluloid::Actor[:shopify_connector].future.upload_asset(asset)
					else
					end
				end
				removed.each do |asset|
					asset = asset.as_path
					say("REMOVED: #{asset}", :green)
					if theme_file?(asset)
						futures << Celluloid::Actor[:shopify_connector].future.remove_asset(asset)
					else
					end
				end
			end
			listener.start

			loop do

				futures.each do |future|
					asset, response = future.value
					if response
						unless response.success?
							say("[" + Time.now.strftime(TIMEFORMAT) + "] Error: #{asset.relative_to(Quickdraw.getwd)} Failed", :red)
						end
					else
						say("Compiled: #{asset.relative_to(Quickdraw.getwd)}")
					end
					futures.delete(future)
				end

				sleep 0.2
			end

		rescue
			puts "exiting...."
		end

		private

		def errors_from_response(response)
			return unless response.parsed_response

			errors = response.parsed_response["errors"]

			case errors
				when NilClass
					''
				when String
					errors
				else
					errors.values.join(", ")
			end
		end

		def theme_file?(asset)
			asset.as_path.relative_to(Quickdraw.getwd).to_s[/^theme\//]
		end

		def src_file?(asset)
			asset.as_path.relative_to(Quickdraw.getwd).to_s[/^src\//]
		end

	end
end
