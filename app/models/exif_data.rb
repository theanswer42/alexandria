class ExifData < ActiveRecord::Base
  belongs_to :photo
  serialize :exif_data

  attr_accessible :exif_data

end
