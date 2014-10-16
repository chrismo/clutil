require "#{File.dirname(__FILE__)}/install"
init

$cldir = File.join($siteverdir, "cl")
$clutildir = File.join($cldir, "util")
$clutiltestdir = File.join($clutildir, "test")

$libfiles = { 'util.rb'    => $cldir ,

              "file.rb"    => $clutildir ,
              "win.rb"     => $clutildir ,
              "dirsize.rb" => $clutildir ,
              "test.rb" => $clutildir ,
              "time.rb" => $clutildir ,
              "console.rb" => $clutildir ,
              "progress.rb" => $clutildir ,
              "install.rb" => $clutildir ,
              "smtp.rb"    => $clutildir ,
              "string.rb"  => $clutildir ,
              "version.rb" => $clutildir ,
              "clqsend.rb"   => $bindir ,

              "./test/dirsizetest.rb" => $clutiltestdir,
              "./test/filetest.rb" => $clutiltestdir ,
              "./test/installtest.rb" => $clutiltestdir ,
              "./test/progresstest.rb" => $clutiltestdir,
              "./test/stringtest.rb" => $clutiltestdir,
              "./test/versiontest.rb" => $clutiltestdir,
              "./test/wintest.rb" => $clutiltestdir
            }

if __FILE__ == $0
  install_lib($libfiles)
end
