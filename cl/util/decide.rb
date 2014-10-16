class Integer
  def odd?
    self.divmod(2)[1] != 0
  end
end

def decide(items)
  round = 1
  while items.length > 1
    items.sort! { rand(3) - 1 }
    
    pairs = []
    gate = 0
    items.each { |item|
      pairs << [item] if gate == 0
      pairs[-1] << item if gate == 1
      gate = gate ^ 1
    }
    
    puts "=" * 20
    puts "Round #{round} :: #{pairs.length} pairs".center(20)
    puts "=" * 20
    
    pairs.each do |pair|
      begin
        puts "1) #{pair[0]}"
        puts "2) #{pair[1]}"
        print "keep: "
        keeper = gets.chomp
      end while keeper !~ /[12]/
      delete = (keeper.to_i - 1) ^ 1
      items.delete(pair[delete])
    end
    round += 1
  end

  puts "Winner is: #{items[0]}"
end

if __FILE__ == $0
  def do_test
    puts "Odd number item list test"
    items = ["a", "b", "c", "d", "e"]
    decide(items)
    
    puts "Even number item list test"
    items = ["a", "b", "c", "d"]
    decide(items)
  end
  
  list_fn = ARGV[0]
  ARGV.clear
  
  if list_fn =~ /test/i
    do_test
    exit
  end
  
  if list_fn.nil? || !File.exists?(list_fn)
    puts "Usage: #{File.basename(__FILE__)} [list_filename]"
    exit
  end
  
  items = File.readlines(list_fn)
  items.delete_if { |item| item.chomp.empty? }
  items.compact!
  decide(items)
end

