require File.dirname(__FILE__) + '/../test'
require File.dirname(__FILE__) + '/../dirsize'
require 'test/unit'

TestData = Struct.new("TestData",
  :clusterSize,
  :expectedFileSize,
  :expectedDiskSpace,
  :expectedFileSizeIncludeSubs,
  :expectedDiskSpaceIncludeSubs,
  :expectedFileCount,
  :expectedAvgFileSize,
  :expectedFileCountIncludeSubs,
  :expectedAvgFileSizeIncludeSubs
)

class TestDirSize < TempDirTest
  def setup
    super
    @test_data = TestData.new
  end

  def test_larger_singleton
    make_sample_text_file('', 5000)
    @test_data.clusterSize = 4096
    @test_data.expectedFileSize = 5000
    @test_data.expectedDiskSpace = (4096 * 2)
    @test_data.expectedFileSizeIncludeSubs = 5000
    @test_data.expectedDiskSpaceIncludeSubs = (4096 * 2)
    @test_data.expectedFileCount = 1
    @test_data.expectedAvgFileSize = 5000
    @test_data.expectedFileCountIncludeSubs = 1
    @test_data.expectedAvgFileSizeIncludeSubs = 5000
    do_test_dir_size(@test_data)
  end

  def do_test_dir_size(test_data)
    dir_size = DirSize.new
    dir_size.directory = @temp_dir
    dir_size.clusterSize = test_data.clusterSize
    dir_size.getSize
    assert_equal(test_data.expectedFileSize, dir_size.fileSize(false))
    assert_equal(test_data.expectedDiskSpace, dir_size.diskSpace(false))
    assert_equal(test_data.expectedFileSizeIncludeSubs, dir_size.fileSize(true))
    assert_equal(test_data.expectedDiskSpaceIncludeSubs,
      dir_size.diskSpace(true))
    assert_equal(test_data.expectedDiskSpace - test_data.expectedFileSize,
      dir_size.unusedDiskSpace(false))
    assert_equal(
      (test_data.expectedDiskSpaceIncludeSubs -
        test_data.expectedFileSizeIncludeSubs), dir_size.unusedDiskSpace(true))
    assert_equal(test_data.expectedFileCount, dir_size.fileCount(false))
    assert_equal(test_data.expectedAvgFileSize, dir_size.avgFileSize(false))
    assert_equal(test_data.expectedFileCountIncludeSubs,
      dir_size.fileCount(true))
    assert_equal(test_data.expectedAvgFileSizeIncludeSubs,
      dir_size.avgFileSize(true))
  end

  def test_small_singleton
    make_sample_text_file('', 1000)
    @test_data.clusterSize = 4096
    @test_data.expectedFileSize = 1000
    @test_data.expectedDiskSpace = (4096 * 1)
    @test_data.expectedFileSizeIncludeSubs = 1000
    @test_data.expectedDiskSpaceIncludeSubs = (4096 * 1)
    @test_data.expectedFileCount = 1
    @test_data.expectedAvgFileSize = 1000
    @test_data.expectedFileCountIncludeSubs = 1
    @test_data.expectedAvgFileSizeIncludeSubs = 1000
    do_test_dir_size(@test_data)
  end

  def test_sub_dir
    make_sub_dir('suba')
    make_sub_dir("suba\\suba1")
    make_sample_text_file('', 1000)
    make_sample_text_file('suba', 1000)
    make_sample_text_file("suba\\suba1", 1000)
    make_sample_text_file("suba\\suba1", 2000)
    @test_data.clusterSize = 4096
    @test_data.expectedFileSize = 1000
    @test_data.expectedDiskSpace = (4096 * 1)
    @test_data.expectedFileSizeIncludeSubs = 5000
    @test_data.expectedDiskSpaceIncludeSubs = (4096 * 4)
    @test_data.expectedFileCount = 1
    @test_data.expectedAvgFileSize = 1000
    @test_data.expectedFileCountIncludeSubs = 4
    @test_data.expectedAvgFileSizeIncludeSubs = 1250
    do_test_dir_size(@test_data)
  end

  def test_empty_dir
    @test_data.clusterSize = 4096
    @test_data.expectedFileSize = 0
    @test_data.expectedDiskSpace = 0
    @test_data.expectedFileCount = 0
    @test_data.expectedAvgFileSize = 0
    @test_data.expectedFileCountIncludeSubs = 0
    @test_data.expectedAvgFileSizeIncludeSubs = 0
    @test_data.expectedFileSizeIncludeSubs = 0
    @test_data.expectedDiskSpaceIncludeSubs = 0
    do_test_dir_size(@test_data)
  end
end
