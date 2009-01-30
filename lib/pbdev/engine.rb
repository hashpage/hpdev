module PBDev
  
  class EngineRepo < Repo

    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = EngineCheckout.new(@mode, @kind, dir, tempdir, url)
      js = wc.serve("pagebout.js")
      css = wc.serve("pagebout.css")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{js}" pagebout.js`
        `mv "#{css}" pagebout.css`
        `rm -rf .temp`
      end
      dir
    end

  end

  class EngineCheckout < Checkout

    def serve(path)
      resource_path = File.join(@path, path)
      return bakein(path, "js", %w(tpl html js), "PB = { templates:{} };") if path=="pagebout.js"
      return bakein(path, "css", %w(css)) if path=="pagebout.css"
      resource_path
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