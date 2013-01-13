class Document < ActiveRecord::Base
  acts_as_taggable

  validates :filename, :checksum, :timestamp, :presence => true
  validates :checksum, :uniqueness => true
  
  attr_accessible :filename, :thumbnail, :checksum, :name, :description, :timestamp, :imported_at
  
  def self.type_for(path)
    extension = File.extname(path).downcase
    {".jpg" => Photo,
      ".jpeg" => Photo}[extension] || Document
  end

  def self.timestamp_for(path)
    timestamp = File.mtime(filename)
  end

  def self.import!(path, tags, options)
    result = options[:result]

    # first, we get the checksum and skip if its a dup.
    sha1sum = Digest::SHA1.new
    file = File.open(path, 'rb')
    sha1sum << file.read()
    file.close
    
    checksum = sha1sum.to_s
    if (document = Document.find_by_checksum(checksum))
      result[:skipped] += 1
      Rails.logger.info("#{path} skipped, file already exists: #{document.library_filename}")
      return
    end
    
    # Not a dup. Create the document object
    type = self.type_for(path)
    timestamp = type.timestamp_for(path)
    ext = File.extname(path)
    name = File.basename(path, ext)
    timestamp_path = timestamp.strftime("%Y/%m")
    destination_filename = File.join(timestamp_path, "#{checksum}#{ext.downcase}")
    
    document = type.new(:filename => destination_filename, :checksum => checksum, :name => name, :timestamp => timestamp)
    document.tag_list += tags
    
    if document.valid?
      file_base_path = File.join(BASE_PATH, timestamp_path)
      FileUtils.mkdir_p(file_base_path)
      FileUtils.cp(path, File.join(BASE_PATH, destination_filename))
      document.save!
    else
      Rails.logger.error("imported document invalid for path: #{path}")
      result[:errors] += 1
    end
  end

  def self.import_directory(path, tags, options)
    result = {:errors => 0, :total => 0, :skipped => [], :duplicates => [], :album_created => false, :album_used => nil}
    
    Dir.glob(File.join(path, "**", "*")) do |name|
      path_tags = File.dirname(name)[path.length..-1].split("/").select {|n| !n.blank? }
      image_tags = (tags + path_tags).collect {|t| t.downcase }.uniq

      result[:total] += 1
      self.import!(name, image_tags, options)
    end
  end
  
  def library_filename
    File.join(BASE_PATH, filename)
  end
end
