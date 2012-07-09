class Roll < ActiveRecord::Base
  attr_accessible :started_at, :finished_at, :name
  
  validates :started_at, :finished_at, :presence => true
  validates :name, :uniqueness => true
  
  validate :validate_roll_timestamps
  
  has_many :photos

  def self.find_or_create_roll_for(timestamp)
    max_roll = Roll.last
    max_roll_id = max_roll ? max_roll.id : 0
    roll = self.roll_for_timestamp(timestamp).first || Roll.create!(:started_at => timestamp, :finished_at => timestamp, :name => "Roll #{max_roll_id + 1}")
    
  end

  private
  def self.roll_for_timestamp(timestamp)
    self.where("? between date_sub(started_at, interval 1 day) and date_add(finished_at, interval 1 day)", timestamp)
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
