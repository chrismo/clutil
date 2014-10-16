require 'date'

class Time
  DAY = (60 * 60 * 24)

  def days_ago(days)
    self - (DAY * days)
  end
  
  def days_ahead(days)
    days_ago(-days)
  end
end

class Date  
  def days_ago(days)
    self - days
  end

  def days_ahead(days)
    days_ago(-days)
  end
  
  def years_ago(years)
    self << (12 * years)    
  end
  
  def years_ahead(years)
    years_ago(-years)
  end
  
  def mdy
    "#{month}/#{day}/#{year}"
  end
end
