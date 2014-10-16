class Progress
  def initialize(total)
    @total = total
    @current = 0
  end

  def start
    @start = Time.now
    @in_place_called_already = false
  end

  def step
    @current += 1
  end

  def elapsed
    (Time.now - @start)
  end

  def format_seconds(seconds)
    minutes, seconds = seconds.divmod 60
    hours, minutes = minutes.divmod 60
    sprintf("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def elapsedf
    format_seconds(elapsed)
  end

  def done
    @current
  end

  def remaining
    @total - @current
  end

  def est_remaining_time
    ((elapsed / done) * remaining)
  end

  def est_remaining_timef
    format_seconds(est_remaining_time)
  end

  def progress(doStep=false)
    step if doStep
    "#{@current.to_s}/#{@total.to_s} done. Elapsed: #{elapsedf} Est Remain: #{est_remaining_timef}"
  end


  def pct_done
    if @total > 0
      pct = ((done.to_f / @total.to_f) * 100).to_i
    else
      pct = 0
    end

    pct.to_s.rjust(3) + '%'
  end

  def in_place_pct(doStep=false)
    step if doStep
    rubout = 8.chr
    out = ''
    out << (rubout * 4) if @in_place_called_already
    out << pct_done
    @in_place_called_already = true
    out
  end
end
