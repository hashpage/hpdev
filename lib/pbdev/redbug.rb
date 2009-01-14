module PBDev
  
  class RedbugRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = RedbugCheckout.new(@mode, @kind, dir, tempdir, url)
      filename1 = wc.serve("redbug.js")
      filename2 = wc.serve("redcode.js")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{filename1}" redbug.js`
        `mv "#{filename2}" redcode.js`
        `rm -rf .temp`
      end
      dir
    end
  end

  class RedbugCheckout < Checkout
    def prepare_bundle()
      @bundle1 = Bundle.new("1", {
        :source_root => File.join(@path, "redbox"),
        :build_mode => @mode,
        :build_root => temp("1"),
        :build_kind => :redbug
      })
      @bundle2 = Bundle.new("2", {
        :source_root => File.join(@path, "redcode"),
        :build_mode => @mode,
        :build_root => temp("2"),
        :build_kind => :redbug
      })
    end
    
    def serve(path)
      resource_path = File.join(@path, path)
      return resource_path unless path=="redbug.js" || path=="redcode.js"
      
      case path
      when "redbug.js"
        bundle = @bundle1
      when "redcode.js"
        bundle = @bundle2
      end
      bakein(path, bundle)
    end

    def replace_macros(source)
      source.gsub("\#{REDBUG_URL}", @url)
    end
  end
  
end