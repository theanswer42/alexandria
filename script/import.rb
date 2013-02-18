path = ARGV[0]
tags = ARGV[1..-1] || []

puts "Importing path: #{path} with tags: #{tags.inspect}"

result = Document.import_file(path, tags)

puts "Done. #{result.inspect}."
