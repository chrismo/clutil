module ClUtilNet
  def ping(host)
    (`ping -n 1 #{host}` =~ "Request timed out") == nil
  end
end

class NetUse
  def initialize(unc, user='', password='')
    @unc = unc
    @user = user
    @password = password
  end

  def attached?

  end

  def attach(drive='')

  end

  def detach
    
  end
end

if __FILE__ == $0
  include ClUtilNet
  
  puts "Pinging 66.169.210.208"
  puts ping("66.169.210.208")
  
  puts "Pinging localhost"
  puts ping("localhost")
end
