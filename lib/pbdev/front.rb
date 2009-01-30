module PBDev
  
  class FrontRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = FrontCheckout.new(@mode, @kind, dir, tempdir, url)
      js = wc.serve("front.js")
      css = wc.serve("front.css")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{js}" front.js`
        `mv "#{css}" front.css`
        `rm -rf .temp`
      end
      dir
    end
  end

  class FrontCheckout < Checkout
    def serve(path)
      resource_path = File.join(@path, path)
      PB.logger.debug(resource_path)
      return bakein(path, "js", %w(tpl html js), "window.FT = { templates:{} };") if path=="front.js"
      return bakein(path, "css", %w(css)) if path=="front.css"
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