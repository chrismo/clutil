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
         File.exist?(dst) &&
         (
           (File.stat(src).mtime != File.stat(dst).mtime) ||
           (File.stat(src).size != File.stat(dst).size)
         )
       ) || !File.exist?(dst) || bincompare
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
    to_h_size(File.size(filename))
  end

  def to_h_size(size)
    return '0B' if size == 0
    units = %w{B KB MB GB TB}
    e = (Math.log(size) / Math.log(1024)).floor
    s = "%.0f" % (size.to_f / 1024**e)
    "#{s}#{units[e]}"
  end
end

class ClUtilFile
  def ClUtilFile.delTree(rootDirName, pattern='*')
    if (rootDirName == '/') or (rootDirName.empty?)
      raise 'Cannot delete root or empty?'
    end

    if !File.exist?(rootDirName)
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
      Dir.mkdir(to) unless FileTest.exist?(to)
      Dir.chdir(to)

      dirContents = Dir["#{from}/*"]
      dirContents.each { |entry|
        file = File.basename(entry)

        if FileTest.directory?(entry)
          Dir.mkdir(file) unless FileTest.exist?(file)
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
