$LOAD_PATH << '..'
require 'progress'

p = Progress.new(10)
p.start
(0..9).each do |x| puts p.progress(true); sleep 0.5 end

p = Progress.new(10)
p.start
(0..9).each do |x| print p.in_place_pct(true); sleep 0.5 end
