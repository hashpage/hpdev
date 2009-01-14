module PBDev
  
  class EngineRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = EngineCheckout.new(dir, tempdir, url)
      
      filename = wc.serve("pagebout.js", :production)
      
      remove_intermediate(dir)
      
      Dir.chdir(dir) do
        # move baked file in
        `mv "#{filename}" pagebout.js`

        # remove temp
        `rm -rf .temp`
      end
      
      dir
    end
  end

  class EngineCheckout < Checkout
    def serve(path)
      resource_path = File.join(@path, path)
      return resource_path unless path=="pagebout.js"

      bakein(path)
    end

    def replace_macros(source)
      source.gsub("\#{ENGINE_URL}", @url)
    end
  end
end