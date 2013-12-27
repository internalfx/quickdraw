require 'erb'
require 'listen'
require 'pathname'


class Namespace
	def initialize(hash={})
		hash.each do |key, value|
			singleton_class.send(:define_method, key) { value }
		end
	end

	def get_binding
		binding
	end
end

@ns = Namespace.new()
@path = Dir.pwd
@watched_files = Pathname.glob("#{@path}/**/*.erb")

def compile_file(filepath)
	if File.exists?(filepath)
		pathname = Pathname.new(filepath)
		relapath = pathname.relative_path_from(Pathname.pwd)
		targetpath = relapath.to_s.gsub(/^src/, 'theme').gsub('.erb', '')
		template = ERB.new(File.read(filepath))
		File.write("#{targetpath}", template.result(@ns.get_binding))
	end
end

#Compile all files on startup
puts "Compiling Files..."
@watched_files.each do |filepath|
	compile_file(filepath)
end

puts "Watching for changes..."
listener = Listen.to(@path + '/src', :force_polling => true) do |modified, added, removed|
	modified.each do |filepath|
		puts "MODIFIED: #{filepath}"
		compile_file(filepath)
	end
	added.each do |filepath|
		puts "ADDED: #{filepath}"
		compile_file(filepath)
	end
	removed.each do |filepath|
		puts "REMOVED: #{filepath}"
	end
end
listener.start
sleep