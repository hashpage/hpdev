module PBDev
  
  class FrontRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = FrontCheckout.new(@mode, @kind, dir, tempdir, url)
      filename = wc.serve("front.js")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{filename}" front.js`
        `rm -rf .temp`
      end
      dir
    end
  end

  class FrontCheckout < Checkout
    def serve(path)
      resource_path = File.join(@path, path)
      PB.logger.debug(resource_path)
      return resource_path unless path=="front.js"
      bakein(path)
    end
  end
end