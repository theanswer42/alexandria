path = ARGV[0]
tags = ARGV[1..-1] || []

# puts path.inspect
# puts tags.inspect

unless File.directory?(path)
  puts "path: #{path} is not a directory"
  return 1
end

result = Document.import_directory(path, tags)
puts result.inspect
