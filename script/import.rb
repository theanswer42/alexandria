path = ARGV[0]
tags = ARGV[1..-1] || []

# puts path.inspect
# puts tags.inspect

result = Document.import_file(path, tags)
puts result.inspect
