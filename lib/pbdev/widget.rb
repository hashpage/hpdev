module PBDev
  
  class WidgetRepo < Repo

    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = WidgetCheckout.new(@mode, @kind, dir, tempdir, url)
      filename = wc.serve("index.js")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{filename}" index.js`
        `rm -rf .temp`
      end
      dir
    end
  end
  
  class WidgetCheckout < Checkout
    def serve(path)
      ext = File.extname(path)
      basename = File.basename(path, ".js")
      resource_path = File.join(@path, path)
      raise ResourceNotFoundError.new(resource_path) unless File.exists?(resource_path)
      raise IntermediateFileError.new(resource_path) if ext==".tpl" || ext==".html" || ext==".css" || (ext==".js" && basename!="index")
      return resource_path unless ext==".js" # images and other static files
      # the path is index.js
      bakein(path)
    end

  end
end