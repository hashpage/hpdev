module PBDev
  
  class SystemRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = SystemCheckout.new(@mode, @kind, dir, tempdir, url)
      filename = wc.serve("system.js")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{filename}" system.js`
        `rm -rf .temp`
      end
      dir
    end
  end

  class SystemCheckout < Checkout
    def serve(path)
      resource_path = File.join(@path, path)
      PB.logger.debug(resource_path)
      return resource_path unless path=="system.js"

      bakein(path)
    end

    def replace_macros(source)
      source.gsub("\#{SYSTEM_URL}", @url)
    end
  end
end