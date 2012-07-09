class Photo < ActiveRecord::Base
  validates :filename, :checksum, :timestamp, :presence => true
  validates :checksum, :uniqueness => true
  
  has_one :exif_data, :dependent => :destroy

  acts_as_taggable

  attr_accessible :filename, :thumbnail, :checksum, :name, :description, :timestamp, :imported_at

  belongs_to :roll
  before_save :assign_roll
  after_save :modify_roll_timestamps

  belongs_to :album

  def self.config
    unless @config
      config_file = File.open(Rails.root.join('config', 'alexandria.yml'), 'r')
      @config = YAML.load(config_file.read())
      config_file.close
    end
    @config[Rails.env]
  end

  def self.import_directory(path, tags, options={})    
    result = {:total => 0, :exif => 0, :skipped => [], :duplicates => [], :album_created => false, :album_used => nil}

    album_name = options[:album_name]
    if !album_name.blank?
      album = Album.find_by_name(album_name)
      unless album
        album = Album.create!(:name => album_name)
        result[:album_created] = true
      end
      result[:album_used] = album.name
    else 
      album = nil
    end
    
    import_base_path_length = File.expand_path(path).length

    imported_at = Time.now.to_i

    Dir.glob(File.join(path, "**", "*")) do |filename|
      result[:total] += 1
      ext = File.extname(filename).downcase
      unless [".jpg", ".jpeg"].include?(ext)
        result[:skipped] << filename
        next
      end
      
      timestamp = File.mtime(filename)
      
      exif_data = EXIFR::JPEG.new(filename)

      if exif_data.exif?
        result[:exif] += 1
        exif_data = exif_data.to_hash
        exif_data[:orientation] = exif_data[:orientation].to_i
        timestamp = exif_data[:date_time]
      else
        exif_data = nil
      end
      
      sha1sum = Digest::SHA1.new
      file = File.open(filename, 'rb')
      sha1sum << file.read()
      file.close
      
      checksum = sha1sum.to_s
      if Photo.find_by_checksum(checksum)
        (result[:duplicate]||=[]) << filename
        next
      end
      
      path_tags = File.dirname(filename)[import_base_path_length..-1].split("/").select {|n| !n.blank? }
      tags = (tags + path_tags).collect {|t| t.downcase }.uniq
      
      destination_filename = File.join(timestamp.strftime("%Y/%m"), "#{checksum}#{ext}")
        
      photo = Photo.new(:filename => destination_filename, :checksum => checksum, :name => File.basename(filename, ext), :description => "", :timestamp => timestamp, :imported_at => imported_at)
      photo.build_exif_data(:exif_data => exif_data)
      photo.tag_list += tags
      
      photo.album = album if album
      
      photo.save!
      
      file_base_path = File.join(Photo.config["base_path"], timestamp.strftime("%Y/%m"))
      FileUtils.mkdir_p(file_base_path)
      FileUtils.cp(filename, File.join(Photo.config["base_path"], destination_filename))
    end
    result
  end

  private

  def assign_roll
    self.roll = Roll.find_or_create_roll_for(self.timestamp)
  end

  def modify_roll_timestamps
    if self.timestamp < self.roll.started_at
      self.roll.update_attributes!(:started_at => self.timestamp)
    elsif self.timestamp > self.roll.finished_at
      self.roll.update_attributes!(:finished_at => self.timestamp)
    end
  end
  
end
