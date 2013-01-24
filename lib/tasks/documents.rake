namespace :documents do 
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

end
