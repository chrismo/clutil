def ifSwitch(switch)
  ARGV.index(switch) != nil
end

alias :if_switch :ifSwitch

def getSwitch(switch)
  value = nil
  i = ARGV.index(switch)
  value = ARGV[i + 1] if i != nil
end

alias :get_switch :getSwitch

def yn_prompt(text, &blk)
  custom_prompt(text + '? (Y/[N]):', /y/i, @yesToAll, &blk)
end

def custom_prompt(text, execReply=/y/i, autoYield=false)
  if !autoYield
    print text
    reply = $stdin.gets.chomp
  else
    puts text
  end
  yield reply if reply =~ execReply || autoYield
end
