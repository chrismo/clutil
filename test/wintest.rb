if Gem::Platform.local.os =~ /mswin/

  $LOAD_PATH << '..'
  require File.dirname(__FILE__) + '/../cl/util/win'
  require 'test/unit'

  class TestUtilWin < Test::Unit::TestCase
    def testDeleteFile
      fileName = "clutilwintest.test.safe.to.delete.txt"
      f = File.new(fileName, File::CREAT)
      f.close
      File.chmod(0644, fileName)
      File.delete(fileName)
      assert(Dir[fileName] == [])

      f = File.new(fileName, File::CREAT)
      f.close
      File.chmod(0444, fileName)
      begin
        File.delete(fileName)
        fail('should have raised exception')
      rescue ClUtilWinErr
        # nada, expected exception
      end
      assert(Dir[fileName] != [])
      File.delete_all(fileName)
      assert(Dir[fileName] == [])
    end

    def test_win_to_rb_path
      assert_equal('c:/temp', File.win_to_rb_path("c:\\temp"))
      assert_equal('c:/temp', File.rbpath("c:\\temp"))
    end

    def test_rb_to_win_path
      assert_equal("c:\\temp", File.rb_to_win_path("c:/temp"))
      assert_equal("c:\\temp", File.winpath("c:/temp"))
    end

    def test_special_folders
      # quirky test, cuz the test code is the production code, but can't
      # think of an easy way to have a hardcode result that would work on
      # any machine. I guess I could go into the registry myself and look
      # one of these up - but hey...

      shell = WIN32OLE.new("WScript.Shell")
      desktop = shell.SpecialFolders(File::DESKTOP)
      assert_equal(desktop, File.special_folders('Desktop'))
    end

    def test_drives
      # does not fully evaluate output
      # just runs to make sure it doesn't blow up
      Windows.drives.each do |drv|
        puts drv.name + ' ' + drv.typedesc
      end
      Windows.drives(Windows::Drives::DRIVE_FIXED).each do |drv|
        puts drv.name + ' ' + drv.typedesc
      end

      Windows::Drives.drives.each do |drv|
        puts drv.name + ' ' + drv.typedesc
      end
      Windows::Drives.drives(Windows::Drives::DRIVE_FIXED).each do |drv|
        puts drv.name + ' ' + drv.typedesc
      end
    end
  end

  class TestSystemReturnExitCode < Test::Unit::TestCase
    def test_system_return_exit_code
      tmpfn = File.join(File.dirname(__FILE__), '_test.child.rb')
      File.delete tmpfn if File.exists?(tmpfn)
      File.open(tmpfn, 'w+') do |f|
        f.puts 'exit(2)'
      end

      cmd = "ruby.exe -C #{File.dirname(tmpfn)} #{File.basename(tmpfn)}"
      assert_equal(2, system_return_exitcode(cmd))
      File.delete tmpfn if File.exists?(tmpfn)
    end
  end

end
