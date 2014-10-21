require 'rbconfig'
require 'find'
require 'fileutils'
require "#{File.dirname(__FILE__)}/console"

module CLabs
  class Install
    include RbConfig

    attr_reader :version, :libdir, :bindir, :sitedir, :siteverdir, :archdir

    def initialize
      init
    end

    # altered copy of rbconfig.rb -> Config::expand
    def custom_expand(val, conf)
      val.gsub!(/\$\(([^()]+)\)/) do |var|
        key = $1
        if CONFIG.key? key
          custom_expand(conf[key], conf)
        else
          var
        end
      end
      val
    end

    def get_conf(customizations)
      conf = {}
      MAKEFILE_CONFIG.each { |k, v| conf[k] = v.dup }
      customizations.each do |k, v|
        conf[k] = v
      end
      conf.each_value do |val|
        custom_expand(val, conf)
      end
      conf
    end

    def init
      prefixdir = get_switch('-p')
      customizations = {}
      customizations['prefix'] = prefixdir if prefixdir
      conf = get_conf(customizations)

      @version = conf["MAJOR"]+"."+conf["MINOR"]
      @libdir = File.join(conf["libdir"], "ruby", @version)

      @bindir =  conf["bindir"]
      @sitedir = conf["sitedir"] || File.join(@libdir, "site_ruby")
      @siteverdir = File.join(@sitedir, @version)
      @archdir = File.join(@libdir, "i586-mswin32")
    end

    def install_executables(files)
      tmpfn = "cl_tmp"
      files.each do |aFile, dest|
        File.open(aFile) do |ip|
          File.open(tmpfn, "w") do |op|
            ruby = File.join($bindir, "ruby")
            op.puts "#!#{ruby}"
            op.write ip.read
          end
        end

        File::makedirs(dest)
        # 0755 I assume means read/write/execute, not needed for Windows
        File::chmod(0755, dest, true)
        File::install(tmpfn, File.join(dest, File.basename(aFile)), 0755, true)
        File::unlink(tmpfn)
      end
    end

    def install_lib(files)
      files.each do |aFile, dest|
        File::makedirs(dest)
        File::install(aFile, File.join(dest, File.basename(aFile)), 0644, true)
      end
    end
  end
end


