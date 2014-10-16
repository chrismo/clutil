require 'cl/util/smtp'

def getSwitch(switch)
  i = ARGV.index(switch)
  if i != nil
    ARGV[i + 1]
  else
    nil
  end
end

def showhelp
  puts '-h   Help'
  puts '-t   To'
  puts '-f   From'
  puts '-bf  file name of body'
  puts '-s   Subject'
  puts '-i   SMTP ip address or server name'
end

if ARGV.include?('-h')
  showhelp
else
  to = getSwitch('-t')
  subj = getSwitch('-s')
  from = getSwitch('-f')
  bodyfn = getSwitch('-bf')
  smtpsrv = getSwitch('-i')
  params = {
    :from.to_s => from,
    :to.to_s => to, 
    :subj.to_s => subj, 
    :bodyfn.to_s => bodyfn,
    :smtpsrv.to_s => smtpsrv
  }
  anymissing = false
  params.each do |key, value| 
    if value == nil
      puts 'missing param <' + key + '>'
      anymissing = true
    end
  end
  
  body = File.readlines(bodyfn).join
  
  if !anymissing
    puts "sending To:#{to} From:#{from} Subj:#{subj}"
    puts body
    sendmail(to, from, subj, body, smtpsrv)
  else
    puts
    showhelp
  end
end
