path = ARGV[0]
tags = ARGV[1..-1]

puts "Importing #{path} with tags (#{tags.join(',')})"
result = Photo.import_directory(path, tags)

puts "Done."
puts "#{result[:total]} total files"
puts "#{result[:skipped].length} files skipped"
puts "#{result[:exif]} files had exif information"
puts "#{result[:duplicates].length} files were dups"
puts "Duplicates:"
puts result[:duplicates]
puts ""
puts "Skipped:"
puts result[:skipped]
puts "---"
