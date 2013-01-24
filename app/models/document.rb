class Document < ActiveRecord::Base
  acts_as_taggable

  validates :filename, :checksum, :timestamp, :presence => true
  validates :checksum, :uniqueness => true
  
  attr_accessible :filename, :thumbnail, :checksum, :name, :description, :timestamp, :imported_at
  
  def self.available_years
    self.select("distinct year(timestamp) as year_timestamp").collect {|d| d.year_timestamp }
  end

  def self.available_months(year)
    self.where(["year(timestamp) = ?", year]).select("distinct month(timestamp) as month_timestamp").collect {|d| d.month_timestamp }
  end

  def self.type_for(path)
    extension = File.extname(path).downcase
    {".jpg" => Photo,
      ".jpeg" => Photo}[extension] || Document
  end

  def self.timestamp_for(path)
    timestamp = File.mtime(path)
  end
  
  # part_size defines how big is the multi-part chunk size.
  #  nil - not multipart. only compute the root
  #  integer - size in MB
  # 
  # returns: 
  #  {:root => root_hash_value, :
  MAX_PART_SIZE = 4.gigabytes
  def parts_for_transport(part_size = MAX_PART_SIZE)
    file = File.open(library_path, 'rb')
    parts = []
    while(data = file.read(1.megabyte))
      sha256sum = Digest::SHA256.new
      sha256sum << data
      parts << {:data => data, :checksum => sha256sum.to_s}
    end

    current_part_size = 1.megabyte
    parts_for_transport = []
    next_parts = []
    
    while true
      parts_for_transport = parts if current_part_size == part_size
      break if parts.length == 1      

      index = 0
      while(!(pair = parts.slice(index,2)).blank?)
        if pair.size == 1
          next_parts << pair[0] 
          next
        end
        
        data = pair[0][:data] + pair[1][:data]
        sha256sum = Digest::SHA256.new
        sha256sum << pair[0][:checksum] + pair[1][:checksum]
        next_parts << {:data => data, :checksum => sha256sum.to_s}
      end
      
      parts = next_parts
      next_parts = []
      current_part_size = current_part_size * 2
    end

    {:tree_hash => parts.first[:checksum], :parts_for_transport => parts_for_transport}
  end

  def self.import!(path, tags, options)
    result = options[:result]

    # first, we get the checksum and skip if its a dup.
    sha256sum = Digest::SHA256.new
    file = File.open(path, 'rb')
    sha256sum << file.read()
    file.close
    
    checksum = sha256sum.to_s
    if (document = Document.find_by_checksum(checksum))
      tag_list = (document.tag_list + tags).uniq
      result[:skipped] += 1
      document.tag_list = tag_list
      document.save!
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

  def self.import_file(path, tags, options={})
    result = {:errors => 0, :total => 0, :skipped => 0}

    if File.file?(path)
      result[:total] += 1
      self.import!(path, tags, options.merge(:result => result))
    elsif File.directory?(path)
      Dir.glob(File.join(path, "**", "*")).each do |name|
        next unless File.file?(name)
        relative_path = File.dirname(name)[path.length..-1] || ""
        path_tags = relative_path.split("/").select {|n| !n.blank? }
        image_tags = (tags + path_tags).collect {|t| t.downcase }.uniq
        
        result[:total] += 1
        self.import!(name, image_tags, options.merge(:result => result))
      end
      Rails.logger.info "import in progress: #{result.inspect}" if result[:total]%100==0
    end
    Rails.logger.info "import done: #{result.inspect}"
    result
  end

  def library_filename
    File.join(BASE_PATH, filename)
  end
end
