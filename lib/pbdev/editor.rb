module PBDev
  
  class EditorRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = EditorCheckout.new(dir, tempdir, url)
      
      filename = wc.serve("editor.js", :production)
      
      remove_intermediate(dir)
      
      Dir.chdir(dir) do
        # move baked file in
        `mv "#{filename}" editor.js`

        # remove temp
        `rm -rf .temp`
      end
      
      dir
    end
  end

  class EditorCheckout < Checkout
    def serve(path, build_mode = :development)
      resource_path = File.join(@path, path)
      PB.logger.debug(resource_path)
      return resource_path unless path=="editor.js"

      bundle = Bundle.new(path, {
        :source_root => @path,
        :build_mode => build_mode,
        :build_root => temp(path),
        :build_kind => :editor
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
      source.gsub("\#{EDITOR_URL}", @url)
    end
  end
end