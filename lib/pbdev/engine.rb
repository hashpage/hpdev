module PBDev
  
  class EngineRepo < Repo

    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = EngineCheckout.new(@mode, @kind, dir, tempdir, url)
      filename = wc.serve("pagebout.js")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{filename}" pagebout.js`
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
      source = super
      mode = 0
      mode = 1 if @mode==:development
      mode = 2 if @mode==:simulation
      source.gsub("serverMode: 0,", "serverMode: #{mode.to_s},")
    end
    
  end
  
end