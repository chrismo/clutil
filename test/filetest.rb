require File.dirname(__FILE__) + '/../cl/util/file'
require File.dirname(__FILE__) + '/../cl/util/test'
require 'test/unit'

# don't inherit from clutiltest.rb.TempDirTest, it uses things that are tested here
class TestUtilFile < Test::Unit::TestCase
  READ_WRITE = 0644
  READ_ONLY = 0444

  def create_test_file(file_name, content, mtime=Time.now, attr=READ_WRITE)
    f = File.new(file_name, 'w+')
    f.puts(content)
    f.flush
    f.close
    File.utime(mtime, mtime, file_name)
    File.chmod(attr, file_name)
  end

  def setup
    @files = []
  end

  def teardown
    @files.each { | filename | File.delete_all(filename) if File.exists?(filename) }
    @dirs.reverse_each { | dirname | Dir.delete(dirname) if File.exists?(dirname) } if @dirs
  end

  def do_test_del_tree(attr)
    @dirs = ['/tmp/utilfiletest',
             '/tmp/utilfiletest/subA',
             '/tmp/utilfiletest/subA/subA1',
             '/tmp/utilfiletest/subA/subA2',
             '/tmp/utilfiletest/subB',
             '/tmp/utilfiletest/subB/subB1',
             '/tmp/utilfiletest/subB/subB1/subB1a']
    @dirs.each { | dir_name | FileUtils::makedirs(dir_name) }
    @files = ['/tmp/utilfiletest/subA/blah.txt',
              '/tmp/utilfiletest/subA/subA1/blah.txt',
              '/tmp/utilfiletest/subA/subA2/blah.txt',
              '/tmp/utilfiletest/subB/blah.txt',
              '/tmp/utilfiletest/subB/subB1/blah.txt',
              '/tmp/utilfiletest/subB/subB1/subB1a/blah.txt']
    @files.each { | filename | create_test_file(filename, 'test content', Time.now, attr) }
    ClUtilFile.delTree(@dirs[0])
    @files.each { | file_name | assert(!File.exists?(file_name)) }
    @dirs.each { | dir_name | assert(!File.exists?(dir_name)) }
  end

  def test_del_tree
    do_test_del_tree(READ_WRITE)
  end

  def test_del_tree_ro_files
    do_test_del_tree(READ_ONLY)
  end

  def test_del_tree_file_name_match
    @dirs = ['/tmp/utilfiletest',
             '/tmp/utilfiletest/subA',
             '/tmp/utilfiletest/subB']
    @dirs.each { | dir_name | FileUtils::makedirs(dir_name) }
    @files_to_stay = ['/tmp/utilfiletest/subA/blah.doc',
                    '/tmp/utilfiletest/subB/blah.doc']
    @files_to_delete = ['/tmp/utilfiletest/subA/blah.txt',
                      '/tmp/utilfiletest/subB/blah.txt']
    @files << @files_to_stay
    @files << @files_to_delete
    @files.flatten!

    @files_to_stay.each { | filename | create_test_file(filename, 'test content') }
    @files_to_delete.each { | filename | create_test_file(filename, 'test content') }
    ClUtilFile.delTree(@dirs[0], '*.txt')
    @files_to_stay.each { | file_name | assert(File.exists?(file_name)) }
    @files_to_delete.each { | file_name | assert(!File.exists?(file_name)) }
    ClUtilFile.delTree(@dirs[0])
    @files_to_stay.each { | file_name | assert(!File.exists?(file_name)) }
    @files_to_delete.each { | file_name | assert(!File.exists?(file_name)) }
    @dirs.each { | dir_name | assert(!File.exists?(dir_name)) }
  end

  def test_del_tree_aging
    @dirs = ['/tmp/utilfiletest',
             '/tmp/utilfiletest/subA',
             '/tmp/utilfiletest/subB']
    @dirs.each { | dir_name | FileUtils::makedirs(dir_name) }
    @files_to_stay = ['/tmp/utilfiletest/subA/blah0.txt',
                    '/tmp/utilfiletest/subB/blah1.txt']
    @files_to_delete = ['/tmp/utilfiletest/subA/blah2.txt',
                      '/tmp/utilfiletest/subB/blah3.txt']
    @files << @files_to_stay
    @files << @files_to_delete
    @files.flatten!

    @files_to_stay.each { | filename | create_test_file(filename, 'test content') }

    day = 60 * 60 * 24
    eight_days = day * 8
    seven_days = day * 7
    @files_to_delete.each { | filename | create_test_file(filename, 'test content', Time.now - eight_days) }

    ClUtilFile.delTree(@dirs[0]) { | file_name |
      (File.mtime(file_name) < (Time.now - seven_days))
    }

    @files_to_stay.each { | file_name | assert(File.exists?(file_name)) }
    @files_to_delete.each { | file_name | assert(!File.exists?(file_name)) }
    ClUtilFile.delTree(@dirs[0])
    @files_to_stay.each { | file_name | assert(!File.exists?(file_name)) }
    @files_to_delete.each { | file_name | assert(!File.exists?(file_name)) }
    @dirs.each { | dir_name | assert(!File.exists?(dir_name)) }
  end

  def test_dir_files
    @dirs = ['/tmp/utilfiletest',
             '/tmp/utilfiletest/subA',
             '/tmp/utilfiletest/subA/subA1',
             '/tmp/utilfiletest/subA/subA2',
             '/tmp/utilfiletest/subB',
             '/tmp/utilfiletest/subB/subB1',
             '/tmp/utilfiletest/subB/subB1/subB1a']
    @dirs.each { | dir_name | FileUtils::makedirs(dir_name) }
    @files = ['/tmp/utilfiletest/subA/blah.txt',
              '/tmp/utilfiletest/subA/subA1/blah.txt',
              '/tmp/utilfiletest/subA/subA2/blah.txt',
              '/tmp/utilfiletest/subB/blah.txt',
              '/tmp/utilfiletest/subB/subB1/blah.txt',
              '/tmp/utilfiletest/subB/subB1/subB1a/blah.txt']
    @files.each { | filename | create_test_file(filename, 'test content') }
    #puts 'Dir.entries'
    #puts Dir.entries('/tmp/utilfiletest/subA/subA1/')
    #puts 'Dir.files'
    #puts Dir.files('/tmp/utilfiletest/subA/subA1/')
    assert_equal(["blah.txt"], Dir.files('/tmp/utilfiletest/subA/subA1/'))
  end
  
  def test_file_extension
    assert_equal('rb', File.extension('/test/file.rb'))
    assert_equal(nil, File.extension('/test/file'))
    assert_equal('rb', File.extension('/test/file.of.some.such.rb'))
  end
end

class TestBackup < TempDirTest

  def setup
    super
    @a_dir = make_sub_dir('a')
    @b_dir = make_sub_dir('b')
  end

  def test_backed_up_because_not_exists
    src = make_sample_text_file('a')
    dst = File.join(@b_dir, File.basename(src))
    assert_equal(true, File.backup(src, dst))
    assert_equal(true, File.exists?(dst))
  end

  def test_not_backed_up_because_exists
    src = make_sample_text_file('a')
    dst = File.join(@b_dir, File.basename(src))
    assert_equal(true, File.backup(src, dst))
    assert_equal(false, File.backup(src, dst))
  end

  def test_backed_up_because_exists_different_mtime
    src = make_sample_text_file('a')
    dst = File.join(@b_dir, File.basename(src))
    assert_equal(true, File.backup(src, dst))

    File.utime(0, 0, dst)
    assert_equal(true, File.backup(src, dst))
  end

  def test_backed_up_because_exists_different_size
    src = make_sample_text_file('a')
    dst = File.join(@b_dir, File.basename(src))
    assert_equal(true, File.backup(src, dst))

    File.open(dst, 'a+') do |f| f.print "bigger" end
    assert_equal(true, File.backup(src, dst))
  end

  def test_not_backed_up_because_exists_byte_diff_but_no_bincompare
    src = make_sample_text_file('a')
    dst = File.join(@b_dir, File.basename(src))
    assert_equal(true, File.backup(src, dst))

    guts = File.read(dst)
    guts.reverse!
    File.open(dst, 'w+') do |f| f.print guts end
    File.utime(File.atime(src), File.mtime(src), dst)
    assert_equal(false, File.backup(src, dst))
  end

  def test_backed_up_because_exists_byte_diff_and_bincompare
    src = make_sample_text_file('a')
    dst = File.join(@b_dir, File.basename(src))
    assert_equal(true, File.backup(src, dst))

    guts = File.read(dst)
    guts.reverse!
    File.open(dst, 'w+') do |f| f.print guts end
    File.utime(File.atime(src), File.mtime(src), dst)
    assert_equal(true, File.backup(src, dst, true))
  end

end

class TestHSize < Test::Unit::TestCase
  def test_to_h_size
    assert_equal '0B', File.to_h_size(0)
    assert_equal '1B', File.to_h_size(1)
    assert_equal '10B', File.to_h_size(10)
    assert_equal '100B', File.to_h_size(100)
    assert_equal '1023B', File.to_h_size(1023)
    assert_equal '1KB', File.to_h_size(1024)
    assert_equal '1000KB', File.to_h_size(1_023_999)
    assert_equal '1001KB', File.to_h_size(1_024_999)
    assert_equal '1MB', File.to_h_size(1_127_000)
    assert_equal '10MB', File.to_h_size(10_127_000)
    assert_equal '18MB', File.to_h_size(19_127_000)
    assert_equal '190MB', File.to_h_size(199_127_000)
    assert_equal '1GB', File.to_h_size(1_199_127_000)
    assert_equal '1TB', File.to_h_size(1_100_199_127_000)
    assert_equal '494TB', File.to_h_size(543_100_199_127_000)
  end
end
