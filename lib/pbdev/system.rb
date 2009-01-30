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
      return bakein(path, "js", %w(tpl html js), "PBS.templates={};") if path=="system.js"
      return bakein(path, "css", %w(css)) if path=="system.css"
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