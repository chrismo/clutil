=begin
code in copyTree includes code from rubycookbook.org under the following license:
--------------------------------------------------------------------------------
Copyright (c) Phil Tomson, Brian Takita

All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so,
provided that the above copyright notice(s) and this permission notice appear in
all copies of the Software and that both the above copyright notice(s) and this
permission notice appear in supporting documentation.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT
SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR ANY
CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall not be
used in advertising or otherwise to promote the sale, use or other dealings in
this Software without prior written authorization of the copyright holder.
--------------------------------------------------------------------------------
(X11 license)
=end

require 'fileutils'

class Dir
  def Dir.empty?(dirname)
    Dir.entries(dirname).length == 2
  end

  def Dir.files(dirname)
    # Dir[dirname + '*'] does the same, except it includes the directory name
    result = []
    Dir.entries(dirname).each do |entry|
      result << entry if File.stat(File.join(dirname, entry)).file?
    end
    result
  end
end

class << File
  def extension(filename)
    res = filename.scan(/\.[^.]*$/)[0].to_s
    res.gsub!(/\./, '')
    res = nil if res.empty?
    res
  end
  
  def delete_all(*files)
    files.flatten!
    files.each do |file|
      # make writable to allow deletion
      File.chmod(0644, file)
      File.delete(file)
    end
  end

  # returns false if up-to-date check passed and the file was not copied.
  # returns true if up-to-date check failed and the file was copied.
  def backup(src, dst, bincompare=false)
    installed = false
    if (
         File.exists?(dst) &&
         (
           (File.stat(src).mtime != File.stat(dst).mtime) ||
           (File.stat(src).size != File.stat(dst).size)
         )
       ) || !File.exists?(dst) || bincompare
      FileUtils.install src, dst, :verbose => true
      installed = true
    end
    
    if !File.stat(dst).writable?
      File.chmod(0644, dst) 
      set_ro = true
    else
      set_ro = false
    end
    match_mtime(src, dst)
    File.chmod(0444, dst) if set_ro
    return installed
  end

  # XP's utime appears to still have a bug when the file's time is within Daylight Saving Time, but
  # the current system time is outside Daylight Saving Time. This method will ensure any difference
  # is compensated for.
  def match_mtime(src, dst)
    new_atime = Time.now
    File.utime(new_atime, File.mtime(src), dst)
    if File.mtime(src) != File.mtime(dst)
      new_mtime = File.mtime(src)
      new_mtime += (File.mtime(src) - File.mtime(dst))
      File.utime(new_atime, new_mtime, dst)
    end
  end

  # human readable size
  def h_size(filename)
    size = File.size(filename)
    return '0B' if size == 0
    units = %w{B KB MB GB TB}
    e = (Math.log(size) / Math.log(1024)).floor
    s = "%.0f" % (size.to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end
end

class ClUtilFile
  def ClUtilFile.delTree(rootDirName, pattern='*')
    if (rootDirName == '/') or (rootDirName.empty?)
      raise 'Cannot delete root or empty?'
    end

    if !File.exists?(rootDirName)
      raise 'rootDirName does not exist'
    end

    # puts all sub-dirs and filenames in array.
    # Sub-dirs will be breadth first search.
    dirsAndFiles = Dir["#{rootDirName}/**/" + pattern]

    # delete all files first
    dirsAndFiles.each do | dirOrFileName |
      if FileTest.file?(dirOrFileName)
        if block_given?
          File.delete_all(dirOrFileName) if yield dirOrFileName
        else
          File.delete_all(dirOrFileName)
        end
      end
    end

    # go through array backward to delete dirs in proper order
    dirsAndFiles.reverse_each do | dirOrFileName |
      if FileTest.directory?(dirOrFileName)
        Dir.delete(dirOrFileName) if Dir.empty?(dirOrFileName)
      end
    end

    Dir.delete(rootDirName) if Dir.empty?(rootDirName)
  end

=begin
  1.8 FileUtils has cp_r in it ...

  def ClUtilFile.copyTree(fromDir, toDir, pattern='*')
    ##################################################################
    # cp_r  - recursive copy
    # usage: cp_r(from,to,file_param,permissions)
    ##################################################################
    def cp_r(from,to,file_param=".*",permissions = 0644)
      Dir.mkdir(to) unless FileTest.exists?(to)
      Dir.chdir(to)

      dirContents = Dir["#{from}/*"]
      dirContents.each { |entry|
        file = File.basename(entry)

        if FileTest.directory?(entry)
          Dir.mkdir(file) unless FileTest.exists?(file)
          cp_r(entry,file,file_param)
          Dir.chdir("..") #get back to the dir we were working on
        else
          if file =~ file_param
              begin
                p = permissions
                if FileTest.executable?(entry)
                   p = 0744 #make it executable
                end
                File.install(entry,file,p)
              rescue
                  puts "could not copy #{entry} to #{file}"
              end
            end
        end
      }
    end #cp_r
    #example usage
    #cp_r("/usr/local","my_tmp",".*\.html?")

  end
=end
end


class Dir
  # Dir.mktmpdir creates a temporary directory.
  #
  # [Copied from Ruby 1.9]
  #
  # The directory is created with 0700 permission.
  #
  # The prefix and suffix of the name of the directory is specified by
  # the optional first argument, <i>prefix_suffix</i>.
  # - If it is not specified or nil, "d" is used as the prefix and no suffix is used.
  # - If it is a string, it is used as the prefix and no suffix is used.
  # - If it is an array, first element is used as the prefix and second element is used as a suffix.
  #
  #  Dir.mktmpdir {|dir| dir is ".../d..." }
  #  Dir.mktmpdir("foo") {|dir| dir is ".../foo..." }
  #  Dir.mktmpdir(["foo", "bar"]) {|dir| dir is ".../foo...bar" }
  #
  # The directory is created under Dir.tmpdir or
  # the optional second argument <i>tmpdir</i> if non-nil value is given.
  #
  #  Dir.mktmpdir {|dir| dir is "#{Dir.tmpdir}/d..." }
  #  Dir.mktmpdir(nil, "/var/tmp") {|dir| dir is "/var/tmp/d..." }
  #
  # If a block is given,
  # it is yielded with the path of the directory.
  # The directory and its contents are removed
  # using FileUtils.remove_entry_secure before Dir.mktmpdir returns.
  # The value of the block is returned.
  #
  #  Dir.mktmpdir {|dir|
  #    # use the directory...
  #    open("#{dir}/foo", "w") { ... }
  #  }
  #
  # If a block is not given,
  # The path of the directory is returned.
  # In this case, Dir.mktmpdir doesn't remove the directory.
  #
  #  dir = Dir.mktmpdir
  #  begin
  #    # use the directory...
  #    open("#{dir}/foo", "w") { ... }
  #  ensure
  #    # remove the directory.
  #    FileUtils.remove_entry_secure dir
  #  end
  #
  def Dir.mktmpdir(prefix_suffix=nil, tmpdir=nil)
    case prefix_suffix
    when nil
      prefix = "d"
      suffix = ""
    when String
      prefix = prefix_suffix
      suffix = ""
    when Array
      prefix = prefix_suffix[0]
      suffix = prefix_suffix[1]
    else
      raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
    end
    tmpdir ||= Dir.tmpdir
    t = Time.now.strftime("%Y%m%d")
    n = nil
    begin
      path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      path << "-#{n}" if n
      path << suffix
      Dir.mkdir(path, 0700)
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry
    end

    if block_given?
      begin
        yield path
      ensure
        FileUtils.remove_entry_secure path
      end
    else
      path
    end
  end
end
