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
    def serve(path, build_mode = :development)
      resource_path = File.join(@path, path)
      return resource_path unless path=="pagebout.js"

      bundle = Bundle.new(path, {
        :source_root => @path,
        :build_mode => build_mode,
        :build_root => temp(path),
        :build_kind => :engine
      })
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
      source.gsub("\#{ENGINE_URL}", @url)
    end
  end
end