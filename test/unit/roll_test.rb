require 'test_helper'

class RollTest < ActiveSupport::TestCase
  def test_validations
    existing_roll = rolls(:roll_one)

    roll = Roll.new(:started_at => 6.days.ago, :name => "Roll 2")
    assert !roll.valid?
    
    roll = Roll.new(:started_at => 6.days.ago, :finished_at => 5.days.ago, :name => "Roll 1")
    assert !roll.valid?
    
    roll = Roll.new(:started_at => 4.days.ago, :finished_at => 5.days.ago, :name => "Roll 4")
    assert !roll.valid?

    roll = Roll.new(:started_at => existing_roll.finished_at-6.hours, :finished_at => Time.now.midnight, :name => "Roll 4")
    assert !roll.valid?

    roll = Roll.new(:started_at => existing_roll.finished_at-6.hours, :finished_at => Time.now.midnight, :name => "Roll 4")
    assert !roll.valid?

    roll = Roll.new(:finished_at => existing_roll.finished_at-6.hours, :started_at => existing_roll.finished_at-7.days, :name => "Roll 4")
    assert !roll.valid?
  end
  
  def test_roll_for_timestamp
    existing_roll = rolls(:roll_one)
    
    roll = Roll.find_or_create_roll_for(existing_roll.finished_at - 6.hours)
    assert_equal roll.id, existing_roll.id
    
    max_id = Roll.last.id
    roll = Roll.find_or_create_roll_for(existing_roll.finished_at + 2.days)
    assert roll.id != existing_roll.id
    assert_equal roll.name, "Roll #{max_id+1}"
  end
  
end
