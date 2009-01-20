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

    def replace_macros(source)
      source = super
      mode = 0
      mode = 1 if @mode==:development
      mode = 2 if @mode==:simulation
      source.gsub("serverMode: 0,", "serverMode: #{mode.to_s},")
    end
  end
end