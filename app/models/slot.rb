class Slot < ActiveRecord::Base

  # === List of columns ===
  #   id         : integer 
  #   time       : datetime 
  #   room       : integer 
  #   created_at : datetime 
  #   updated_at : datetime 
  # =======================

  has_and_belongs_to_many :tutors
  has_many :slot_changes

  #TODO Validate whether a tutor is assigned to both rooms of the same time.
  validate :valid_room
  validate :valid_tutor
  validates :room, :presence => true
  validates :time, :presence => true

  @day_to_wday = {"Monday"=>1, "Tuesday"=>2, "Wednesday"=>3, "Thursday"=>4, "Friday"=>5}
  @shortday_to_wday = {"Mon"=>1, "Tue"=>2, "Wed"=>3, "Thu"=>4, "Fri"=>5}
  @room_to_int = {"Cory"=>0, "Soda"=>1}
  class << self
    attr_reader :day_to_wday, :room_to_int, :shortday_to_wday
    def extract_day_time(str)
      begin
        wday = Slot.shortday_to_wday[str[0..2]]
        hour = Integer(str[3..4])
        return wday, hour
      rescue
        return nil
      end
    end
    def get_from_string(str)
      daytime = extract_day_time(str)
      time = get_time(daytime[0], daytime[1])
      room = room_to_int[str[5..8]] || {"C"=>0, "S"=>1}[str[5..5]]
      return find_by_time_and_room(time, room)
    end
    def get_time(wday, hour)
      base = Time.at(0).utc
      thetime = hour.hours + ((wday - base.wday) % 7).days
      Time.at(thetime.value)
    end

    def get_time_str(wday, hour)
      base = Time.at(0)
      thetime = hour.hours + ((wday - base.wday) % 7).days
      Time.at(thetime.value).strftime('%a%H')
    end
    def find_by_wday(wday)
      slots = all
      slots.select {|slot| slot.wday == wday}
    end
    def find_by_wday_and_room(wday, room)
      slots = find_by_wday(wday)
      slots.select {|slot| slot.room == room}
    end
   def find_by_wday_hour_and_room(wday, hour, room)
      slots = all
      slots.select {|slot| slot.wday == wday and slot.hour == hour and slot.room == room}
    end
  end

  def to_s
    time.utc.strftime('%a%H') + get_room()[0..0]
  end

  def get_room()
    if room == 0 then
      "Cory"
    elsif room == 1 then
      "Soda"
    else
      "Undefined"
    end
  end

  def hour
    time.utc.hour
  end

  def wday
    time.utc.wday
  end

  def valid_room
    if !room.blank?
      errors[:room] << "room needs to be 0 (Cory) or 1 (Soda)" unless (room == 0 or room == 1)
    end
  end

  def valid_tutor
    valid = true
    otherTutors = Slot.find(:first, :conditions => ["time = ? and room != ?", time, room]).tutors
    for tutor1 in tutors
      for tutor2 in otherTutors
        if tutor1 == tutor2
          valid = false
          break
        end
      end
    end
    errors[:tutor] << "A tutor cannot be in two places at once!" unless valid
  end
  
  def availabilities
    return Availability.where(:time=>time)
  end
  def get_all_tutors
    return Availability.where(:time=>time).map{|x| x.tutor}
  end
  def get_available_tutors
    return Availability.where(:time=>time, :preference_level=>1).map{|x| x.tutor}
  end
  def get_preferred_tutors
    return Availability.where(:time=>time, :preference_level=>2).map{|x| x.tutor}
  end
end
