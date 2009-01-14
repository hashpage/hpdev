module PBDev
  
  class WidgetRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = WidgetCheckout.new(dir, tempdir, url)
      
      # bake index.js
      filename = wc.serve("index.js", :production)
      
      remove_intermediate(dir)
      
      Dir.chdir(dir) do
        # move baked file in
        `mv "#{filename}" index.js`

        # remove temp
        `rm -rf .temp`
      end
      
      dir
    end
  end
  
  class WidgetCheckout < Checkout
    def serve(path, build_mode = :development)
      ext = File.extname(path)
      basename = File.basename(path, ".js")
      resource_path = File.join(@path, path)
      raise ResourceNotFoundError.new(resource_path) unless File.exists?(resource_path)
      raise IntermediateFileError.new(resource_path) if ext==".tpl" || ext==".html" || ext==".css" || (ext==".js" && basename!="index")
      return resource_path unless ext==".js" # images and other static files
      # the path is index.js

      bundle = Bundle.new(path, {
        :source_root => @path,
        :build_mode => build_mode,
        :build_root => temp(path),
        :build_kind => :widget
      })
      bundle.build()
      results = []
      %w(js css tpl html).each do |ext|
        baked = bundle.entry_for("baked_index.#{ext}")
        next unless baked
        results << baked.build_path
      end
      final = prepare_final(path, *results)
      minify(final) if bundle.minify?
      final
    end

    def replace_macros(source)
      source.gsub("\#{WIDGET_URL}", @url)
    end
  end
end