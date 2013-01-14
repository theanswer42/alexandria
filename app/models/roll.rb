class Roll < ActiveRecord::Base
  attr_accessible :started_at, :finished_at, :name
  
  validates :started_at, :finished_at, :presence => true
  validates :name, :uniqueness => true
  
  validate :validate_roll_timestamps
  
  has_many :photo_informations

  def self.find_or_create_roll_for(timestamp)
    max_roll = Roll.last
    max_roll_id = max_roll ? max_roll.id : 0
    rolls = self.roll_for_timestamp(timestamp).all
    if rolls.length > 1
      roll = self.merge_rolls!(rolls)
    elsif rolls.length == 1
      roll = rolls.first
    else
      roll = Roll.create!(:started_at => timestamp, :finished_at => timestamp, :name => "Roll #{max_roll_id + 1}")
    end
    roll
  end

  private
  def self.roll_for_timestamp(timestamp)
    self.where("? between date_sub(started_at, interval 1 day) and date_add(finished_at, interval 1 day)", timestamp)
  end

  def self.merge_rolls!(rolls)
    destination_roll = rolls.first

    rolls[1..-1].each do |roll|
      roll.photo_informations.each do |photo_information|
        photo = photo_information.photo
        if photo.timestamp < destination_roll.started_at
          destination_roll.started_at = photo.timestamp
        elsif photo.timestamp > destination_roll.finished_at
          destination_roll.finished_at = photo.timestamp
        end
      end
      PhotoInformation.where(:roll_id => roll.id).update_all(:roll_id => destination_roll.id)
      roll.destroy
    end
    
    destination_roll.save!
    destination_roll
  end
  
  def validate_roll_timestamps
    return unless self.started_at && self.finished_at

    if self.started_at > self.finished_at
      errors.add(:started_at, "cannot be greater than finished_at")
    end
    id_condition = self.new_record? ? "" : "id <> #{self.id}"
    if Roll.roll_for_timestamp(self.started_at).where(id_condition).count > 0
      errors.add(:started_at, "cannot overlap with other roll's timerange")
    end
    
    if Roll.roll_for_timestamp(self.finished_at).where(id_condition).count > 0
      errors.add(:finished_at, "cannot overlap with other roll's timerange")
    end

  end
end
