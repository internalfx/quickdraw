require "quickdraw/version"

module Quickdraw

	NOOPParser = Proc.new {|data, format| {} }
	TIMER_RESET = 5 * 60 + 5
	PERMIT_LOWER_LIMIT = 10

	def self.asset_list
		# HTTParty parser chokes on assest listing, have it noop
		# and then use a rel JSON parser.
		response = Celluloid::Actor[:shopify_connector]
		response = shopify.get(path, :parser => NOOPParser)
		#manage_timer(response)

		assets = JSON.parse(response.body)["assets"].collect {|a| a['key'] }
		# Remove any .css files if a .css.liquid file exists
		assets.reject{|a| assets.include?("#{a}.liquid") }
	end

	def self.config
		@config ||= if File.exist? 'config.yml'
			            config = YAML.load(File.read('config.yml'))
			            config
			          else
				          puts "config.yml does not exist!"
				          {}
			          end
	end

	def self.get()
		puts "Waiting: #{@sleeptime}"
		sleep @sleeptime

		options.merge!({:basic_auth => @auth})
		HTTParty.get(path, options)

		begin
			tries ||= 3
			response = HTTParty.get(path, options)

			puts response.inspect

			if response.code != 200
				raise "Request Failed"
			end

			@api_call_count, @total_api_calls = response.headers['x-shopify-shop-api-call-limit'].split('/')
			@sleeptime = (5 / (@total_api_calls.to_f / @api_call_count.to_f))

			puts "STATUS: #{@sleeptime} - #{@api_call_count} - #{@total_api_calls}"

		rescue => e
			puts e.inspect
			puts "Failed: will retry #{tries} time(s)"
			sleep 1
			retry unless (tries -= 1).zero?
		end

		return response

	end


end
