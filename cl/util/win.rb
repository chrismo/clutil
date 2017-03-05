require 'Win32API'
require 'win32ole'
require File.dirname(__FILE__) + '/file'

# the system cmd in MSVC built ruby does not set $?, so no access to
# the exit code can be had. The following works, but is obtuse enough
# for me to encapsulate in this method.
# Bit slightly modified from - nobu http://ruby-talk.com/76086
def system_return_exitcode(cmd)
  exitcode = nil
  IO.popen(cmd) { |f|
     # must bit shift by 8 to get the error code
     exitcode = Process.waitpid2(f.pid)[1] >> 8
  }
  return exitcode
end

P_WAIT        = 0
P_NOWAIT      = 1
OLD_P_OVERLAY = 2
P_NOWAITO     = 3
P_DETACH      = 4

def async_system(command)
  # http://msdn.microsoft.com/library/en-us/vccore98/html/_crt__spawnv.2c_._wspawnv.asp
  # this is working -- but frequently Segfaults ruby 1.6.6 mswin32

  spawn = Win32API.new("crtdll", "_spawnvp", ['I', 'P', 'P'] ,'L')
  res = spawn.Call(P_NOWAIT, command, '')
  if res == -1
    Win32API.new("crtdll", "perror", ['P'], 'V').call('async_system')
  end
  res
end

# from WinBase.h in SDK
# dwCreationFlag values
NORMAL_PRIORITY_CLASS = 0x00000020

STARTUP_INFO_SIZE = 68
PROCESS_INFO_SIZE = 16

def create_process(command)
  # from WinBase.h in SDK
  # Passing nil for a pointer -- I've seen it work with a P type param and
  # an empty string ... here L with a 0 is the only way that works with
  # CreateProcess. (see FormatMessage in raise_last_win32_error for an
  # example of 'P' and '' that works)
  params = [
    'L', # IN LPCSTR lpApplicationName
    'P', # IN LPSTR lpCommandLine
    'L', # IN LPSECURITY_ATTRIBUTES lpProcessAttributes
    'L', # IN LPSECURITY_ATTRIBUTES lpThreadAttributes
    'L', # IN BOOL bInheritHandles
    'L', # IN DWORD dwCreationFlags
    'L', # IN LPVOID lpEnvironment
    'L', # IN LPCSTR lpCurrentDirectory
    'P', # IN LPSTARTUPINFOA lpStartupInfo
    'P'  # OUT LPPROCESS_INFORMATION lpProcessInformation
  ]
  returnValue = 'I' # BOOL

  startupInfo = [STARTUP_INFO_SIZE].pack('I') + ([0].pack('I') * (STARTUP_INFO_SIZE - 4))
  processInfo = [0].pack('I') * PROCESS_INFO_SIZE
  createProcess = Win32API.new("kernel32", "CreateProcess", params, returnValue)
  if createProcess.call(0, command, 0, 0, 0, NORMAL_PRIORITY_CLASS, 0, 0,
    startupInfo, processInfo) == 0
    raise_last_win_32_error
  end
  processInfo
end

ERROR_SUCCESS = 0x00
FORMAT_MESSAGE_FROM_SYSTEM = 0x1000
FORMAT_MESSAGE_ARGUMENT_ARRAY = 0x2000

def raise_last_win_32_error
  errorCode = Win32API.new("kernel32", "GetLastError", [], 'L').call
  if errorCode != ERROR_SUCCESS
    params = [
      'L', # IN DWORD dwFlags,
      'P', # IN LPCVOID lpSource,
      'L', # IN DWORD dwMessageId,
      'L', # IN DWORD dwLanguageId,
      'P', # OUT LPSTR lpBuffer,
      'L', # IN DWORD nSize,
      'P', # IN va_list *Arguments
    ]

    formatMessage = Win32API.new("kernel32", "FormatMessage", params, 'L')
    msg = ' ' * 255
    msgLength = formatMessage.call(FORMAT_MESSAGE_FROM_SYSTEM +
      FORMAT_MESSAGE_ARGUMENT_ARRAY, '', errorCode, 0, msg, 255, '')
    msg.gsub!("\\000", '')
    msg.strip!
    raise msg
  else
    raise 'GetLastError returned ERROR_SUCCESS'
  end
end

class ClUtilWinErr < Exception
end

class << File
  alias o_delete delete

  def win_api_delete(filename)
    # http://msdn.microsoft.com/library/default.asp?url=/library/en-us/fileio/filesio_5n8l.asp
    # BOOL DeleteFile(
    #  LPCTSTR lpFileName   // file name
    # );

    # delete file if not read only
    fdelete = Win32API.new("kernel32", "DeleteFile", ["P"], "I")
    fdelete.Call(filename) != 0
  end

  # def recycle
    # function SHFileOperation(const lpFileOp: TSHFileOpStruct): Integer; stdcall;
      # TSHFileOpStruct = packed record
        # Wnd: HWND;  //   HWND = type LongWord; Longword	0..4294967295	unsigned 32-bit
        # wFunc: UINT; // UINT = LongWord;
        # pFrom: PWideChar; // pointer to unicode string
        # pTo: PWideChar;
        # fFlags: FILEOP_FLAGS; // FILEOP_FLAGS = Word; Word	0..65535	unsigned 16-bit
        # fAnyOperationsAborted: BOOL; // BOOL = LongBool;  a LongBool variable occupies four bytes (two words).
        # hNameMappings: Pointer;
        # lpszProgressTitle: PWideChar; { only used if FOF_SIMPLEPROGRESS }
      # end;

      # http://msdn.microsoft.com/en-us/shellcc/platform/shell/reference/structures/shfileopstruct.asp
      # see FOF_ALLOWUNDO, specifically
  # end

  def win_file_ro?(filename)
    fFILE_ATTRIBUTE_READONLY = 0x1
    # http://msdn.microsoft.com/library/default.asp?url=/library/en-us/fileio/filesio_9pgz.asp
    # DWORD GetFileAttributes(
    #   LPCTSTR lpFileName   // name of file or directory
    # );
    fgetattr = Win32API.new("kernel32", "GetFileAttributes", ["P"], "N")
    fattr = fgetattr.Call(filename)
    (fattr & fFILE_ATTRIBUTE_READONLY) != 0
  end

  def delete(*files)
    files.flatten!
    files.each do |file|
      if !win_file_ro?(file)
        win_api_delete(file)
      else
        raise ClUtilWinErr.new(file + ' is read only, cannot delete. Use File.delete_all')
      end
    end
  end

  # I wanted to add a second param to delete, called deleteReadOnly with
  # a default value of false but (a) I can't have a default value param
  # after the *files param because (b) I can't have any non *param after
  # the *files param. So, my compromise was a separate method

  # I have no idea why I'm doing an api specific call here.
  # I think when I started this journey, I thought the API
  # call would delete read-only files, then when I learned
  # it wouldn't, I forgot my original purpose and just
  # worked around it. It's silly now -- I've moved delete_all
  # to cl/util/file.rb which is a pure Ruby implementation
  # of this one.

  #def delete_all(*files)
  #  files.flatten!
  #  files.each do |file|
  #    # make writable to allow deletion
  #    File.chmod(0644, file)
  #    win_api_delete(file)
  #  end
  #end

  def create_shortcut(targetFileName, linkName)
    shell = WIN32OLE.new("WScript.Shell")
    scut = shell.CreateShortcut(linkName + '.lnk')
    scut.TargetPath = File.expand_path(targetFileName)
    scut.Save
    scut
  end

  def win_to_rb_path(winpath)
    winpath.gsub(/\\/, '/')
  end

  def rb_to_win_path(rbpath)
    rbpath.gsub('/', "\\")
  end

  alias rbpath win_to_rb_path
  alias winpath rb_to_win_path

  def special_folders(folderName)
    shell = WIN32OLE.new("WScript.Shell")
    shell.SpecialFolders(folderName)
  end
end

module Windows
  def Windows.drives(typeFilter=nil)
    Drives::drives(typeFilter)
  end

  module Drives
    GetDriveType = Win32API.new("kernel32", "GetDriveTypeA", ['P'], 'L')
    GetLogicalDriveStrings = Win32API.new("kernel32", "GetLogicalDriveStrings", ['L', 'P'], 'L')

    DRIVE_UNKNOWN      = 0 # The drive type cannot be determined.
    DRIVE_NO_ROOT_DIR  = 1 # The root path is invalid. For example, no volume is mounted at the path.
    DRIVE_REMOVABLE    = 2 # The disk can be removed from the drive.
    DRIVE_FIXED        = 3 # The disk cannot be removed from the drive.
    DRIVE_REMOTE       = 4 # The drive is a remote (network) drive.
    DRIVE_CDROM        = 5 # The drive is a CD-ROM drive.
    DRIVE_RAMDISK      = 6 # The drive is a RAM disk.
    DriveTypes = {
      DRIVE_UNKNOWN      => 'Unknown',
      DRIVE_NO_ROOT_DIR  => 'Invalid',
      DRIVE_REMOVABLE    => 'Removable/Floppy',
      DRIVE_FIXED        => 'Fixed',
      DRIVE_REMOTE       => 'Network',
      DRIVE_CDROM        => 'CD',
      DRIVE_RAMDISK      => 'RAM'
    }

    Drive = Struct.new('Drive', :name, :type, :typedesc)

    def Drives.drives(typeFilter=nil)
      driveNames = ' ' * 255
      GetLogicalDriveStrings.Call(255, driveNames)
      driveNames.strip!
      driveNames = driveNames.split("\000")
      drivesAry = []
      driveNames.each do |drv|
        type = GetDriveType.Call(drv)
        if (!typeFilter) || (type == typeFilter)
          drive = Drive.new(drv, type, DriveTypes[type])
          drivesAry << drive
        end
      end
      drivesAry
    end
  end
end

class File
  # from WSH 5.6 docs
  ALLUSERSDESKTOP   = "AllUsersDesktop"
  ALLUSERSSTARTMENU = "AllUsersStartMenu"
  ALLUSERSPROGRAMS  = "AllUsersPrograms"
  ALLUSERSSTARTUP   = "AllUsersStartup"
  DESKTOP           = "Desktop"
  FAVORITES         = "Favorites"
  FONTS             = "Fonts"
  MYDOCUMENTS       = "MyDocuments"
  NETHOOD           = "NetHood"
  PRINTHOOD         = "PrintHood"
  PROGRAMS          = "Programs"
  RECENT            = "Recent"
  SENDTO            = "SendTo"
  STARTMENU         = "StartMenu"
  STARTUP           = "Startup"
  TEMPLATES         = "Templates"
end
