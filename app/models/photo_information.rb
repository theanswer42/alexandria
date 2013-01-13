class PhotoInformation < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :photo
  belongs_to :roll

  before_create :extract_exif_info

  before_save :assign_roll

  after_save :modify_roll_timestamps
  
  serialize :exif_data, Hash
  
  private
  def extract_exif_info
    data = EXIFR::JPEG.new(self.photo.library_filename)
    
    if data.exif?
      self.exif_data = data.to_hash
    else
      self.exif_data = {}
    end
  end
  
  def assign_roll
    self.roll = Roll.find_or_create_roll_for(self.photo.timestamp)
  end

  def modify_roll_timestamps
    if self.photo.timestamp < self.roll.started_at
      self.roll.update_attributes!(:started_at => self.photo.timestamp)
    elsif self.photo.timestamp > self.roll.finished_at
      self.roll.update_attributes!(:finished_at => self.photo.timestamp)
    end
  end

end
