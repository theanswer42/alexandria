class Photo < Document
  has_one :photo_information, :dependent => :destroy
  
  after_create :create_photo_information

  belongs_to :album

  def self.timestamp_for(path)
    timestamp = nil
    begin
      exif_data = EXIFR::JPEG.new(path)
      if exif_data.exif?
        exif_data = exif_data.to_hash
        timestamp = exif_data[:date_time] || exif_data[:date_time_original] || exif_data[:date_time_digitized]
      end
    rescue Exception => e
      Rails.logger.error "could not read exif data from: #{path}"
      timestamp = nil
    end
    timestamp = File.mtime(path) if timestamp.blank?
    timestamp
  end

  private

  def create_photo_information
    self.build_photo_information.save!
  end
  
end
