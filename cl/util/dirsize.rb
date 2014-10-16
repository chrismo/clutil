=begin
uses Classes;

type
  { future, make a cache/factory object for TDirSizes, so we don't have to
    recalc dirs we've already sized }

  TDirSize = class(TObject)
  private
    @diskSpace: Int64;
    @fileCount: integer;
    @fileSize: Int64;
    FClusterSize: Int64;
    FDirectory: string;
    FParent: TDirSize;

    FChildDirs: TList;
  public
    constructor Create;
    destructor Destroy; override;

    function AvgFileSize(IncludeSubs: boolean): Int64;
    function DiskSpace(IncludeSubs: boolean): Int64;
    function FileCount(IncludeSubs: boolean): integer;
    function FileSize(IncludeSubs: boolean): Int64;
    procedure GetSize;
    function UnusedDiskSpace(IncludeSubs: boolean): Int64;

    property ChildDirs: TList read FChildDirs;
    property ClusterSize: Int64 read FClusterSize write FClusterSize;
    property Directory: string read FDirectory write FDirectory;
    property Parent: TDirSize read FParent;
    end
=end

class DirSize
  attr_reader :childDirs, :exception
  attr_accessor :clusterSize, :directory, :parent

  def avgFileSize(includeSubs=false)
    aFileCount = fileCount(includeSubs)
    if aFileCount != 0
      fileSize(includeSubs) / aFileCount
    else
      0
    end
  end

  def initialize
    @childDirs = []
    @fileSize = 0
    @diskSpace = 0
    @fileCount = 0
  end

  def diskSpace(includeSubs=false)
    total = 0
    @childDirs.each do |adir|
      total += adir.diskSpace(includeSubs)
    end if includeSubs
    total + @diskSpace
  end

  def fileCount(includeSubs=false)
    result = @fileCount
    @childDirs.each do |adir|
      result += adir.fileCount(includeSubs)
    end if includeSubs
    result
  end

  def fileSize(includeSubs=false)
    total = 0
    @childDirs.each do |adir|
      total += adir.fileSize(includeSubs)
    end if includeSubs
    total + @fileSize
  end

  def getSize(&block)
    @fileSize = 0
    @diskSpace = 0
    @fileCount = 0
    begin
      Dir.foreach(@directory) do |entry|
        if (entry != '.') && (entry != '..')
          entry = File.join(@directory, entry)
          if (File.directory?(entry))
            childDirSize = DirSize.new
            childDirSize.parent = self
            childDirSize.directory = entry
            childDirSize.clusterSize = @clusterSize
            childDirSize.getSize(&block)
            @childDirs << childDirSize
          else
            if !block_given? || yield(entry)
              @fileCount += 1
              @fileSize += File.size(entry)
              @diskSpace += ((@fileSize / @clusterSize) * @clusterSize) + @clusterSize
            end
          end
        end
      end
    rescue Exception => e
      @exception = e  
    end
  end

  def unusedDiskSpace(includeSubs=false)
    diskSpace(includeSubs) - fileSize(includeSubs)
  end
end
