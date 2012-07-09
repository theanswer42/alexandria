require 'test_helper'

class PhotoTest < ActiveSupport::TestCase
  def test_assigns_existing_roll
    r = Roll.first.id
    
    p = Photo.create!(:filename => "a", :checksum => "b", :name => "sdfkj", :description => "dlkjf", :timestamp => 2.days.ago.midnight, :imported_at => Time.now)
    
    assert_equal p.roll_id, r
  end

  def test_assigns_new_roll
    r = Roll.first.id
    
    p = Photo.create!(:filename => "a", :checksum => "b", :name => "sdfkj", :description => "dlkjf", :timestamp => 10.days.ago, :imported_at => Time.now)
    
    assert p.roll_id != r
    
  end
end
