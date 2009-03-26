module HPDev
  
  class WidgetRepo < Repo
    
    def bake_info(path, meta) # hack
      lines = []
      File.open(path, "r") do |f|
        f.each do |line|
          if line =~/HP\.registerWidget\("[^"]*",\{/
            line = $`+$&+"info:{description:'#{meta['description']}',home:'#{meta['home']}'},"+$'
          end
          lines << line
        end
      end
      File.open(path, "w") do |f|
        f << lines
      end
    end

    def postprocess(dir, meta)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = WidgetCheckout.new(@mode, @kind, dir, tempdir, url)
      filename = wc.serve("index.js")

      bake_info(filename, meta)
      
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
      bakein(path, "js", %w(js tpl css html)) # here must go js first
    end

  end
end