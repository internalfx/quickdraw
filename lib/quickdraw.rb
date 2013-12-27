require "quickdraw/version"
require 'pathname'
require 'filepath'

module Quickdraw

	NOOPParser = Proc.new {|data, format| {} }
	TIMER_RESET = 5 * 60 + 5
	PERMIT_LOWER_LIMIT = 10

	def self.config
		@config ||= if File.exist? 'config.yml'
			            config = YAML.load(File.read('config.yml'))
			            config
			          else
				          puts "config.yml does not exist!"
				          {}
			          end
	end

	def self.getwd
		FilePath.getwd
	end

	def self.theme_dir
		FilePath.getwd / 'theme'
	end

	def self.src_dir
		FilePath.getwd / 'src'
	end

end
