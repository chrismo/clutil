require File.dirname(__FILE__) + '/file'
require 'fileutils'
require 'tmpdir'
require 'test/unit'

class TempDirTest < Test::Unit::TestCase
  def set_temp_dir
    @temp_dir = Dir.mktmpdir
  end

  def setup
    @file_name_inc = 0
    set_temp_dir
    FileUtils::makedirs(@temp_dir) if !FileTest.directory?(@temp_dir)
  end

  def teardown
    ClUtilFile.delTree(@temp_dir)
  end

  # to ward off the new Test::Unit detection of classes with no test
  # methods
  def default_test
    super unless(self.class == TempDirTest)
  end
  
  def make_sub_dir(dirname)
    newdirname = File.join(@temp_dir, dirname)
    FileUtils::makedirs(newdirname) if !FileTest.directory?(newdirname)
    newdirname
  end

  def make_sample_text_file(dirname='', size=0)
    crlf_length = 1

    if size == 0
      content = 'this is a sample file'
    else
      content = ''
      (size - crlf_length).times do content << 'x' end
    end

    if dirname.empty?
      sample_file_dir = @temp_dir
    else
      sample_file_dir = File.join(@temp_dir, dirname)
    end

    @file_name_inc += 1
    filename = File.join(sample_file_dir, 'sample' + @file_name_inc.to_s + '.txt')
    File.open(filename, 'w+') do |f|
      f.puts content
    end
    filename
  end
end
