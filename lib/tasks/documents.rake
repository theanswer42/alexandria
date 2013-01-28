namespace :documents do 
  task :batch_archive => [:environment] do 
    puts "Starting import"
    Document.batch_archive!
    puts "Done"
  end

  task :migrate_checksum => [:environment] do 
    puts "Starting upgrade of checksums to sha256"
    total = 0
    errors = 0

    Document.find_in_batches do |documents|
      documents.each do |document|
        total += 1
        # first make sure that the existing checksum matches.
        sha1sum = Digest::SHA1.new
        file = File.open(document.library_filename, 'rb')
        data = file.read()
        sha1sum << data
        if sha1sum.to_s != document.checksum
          puts "ALERT! #{document.id} - has a checksum mismatch!"
          errors += 1
          next
        end
        sha256sum = Digest::SHA256.new
        sha256sum << data
        document.update_attributes!(:checksum => sha256sum.to_s)
      end
      puts "documents processed: #{total} (#{errors} errors)"
    end
  end

  task :migrate_filenames => [:environment] do 
    puts "Starting moving files."
    total = 0
    errors = 0
    
    Document.find_in_batches do |documents|
      documents.each do |document|
        total += 1
        begin
          source_filename = document.library_filename
          extname = File.extname(source_filename)
          dest_filename = File.join(File.dirname(source_filename), "#{document.checksum}#{extname}")
          dirname = File.dirname(document.filename)
          new_filename = "#{dirname}/#{document.checksum}#{extname}"
          # puts "checksum = #{document.checksum}"
          # puts "new filename will be #{new_filename}"
          # puts "mv #{source_filename} to #{dest_filename}"
          document.update_attributes!(:filename => new_filename)
          FileUtils.mv(source_filename, dest_filename)
        rescue Exception => e
          errors += 1
        end
      end
      puts "moved #{total} filenames. (#{errors} errors)"
    end
    puts "Done! moved #{total} filenames. (#{errors} errors)"
  end

end
