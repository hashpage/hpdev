module PBDev
  
  class RedbugRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = RedbugCheckout.new(dir, tempdir, url)
      
      filename = wc.serve("redbug.js", :production)
      
      remove_intermediate(dir)
      
      Dir.chdir(dir) do
        # move baked file in
        `mv "#{filename}" redbug.js`

        # remove temp
        `rm -rf .temp`
      end
      
      dir
    end
  end

  class RedbugCheckout < Checkout
    def serve(path, build_mode = :development)
      resource_path = File.join(@path, path)
      return resource_path unless path=="redbug.js" || path=="redcode.js"
      
      case path
      when "redbug.js"
        bundle = Bundle.new(path, {
          :source_root => File.join(@path, "redbox"),
          :build_mode => build_mode,
          :build_root => temp(path),
          :build_kind => :redbug
        })
      when "redcode.js"
        bundle = Bundle.new(path, {
          :source_root => File.join(@path, "redcode"),
          :build_mode => build_mode,
          :build_root => temp(path),
          :build_kind => :redbug
        })
      end
      results = []
      %w(js css).each do |ext|
        baked = bundle.entry_for("baked_index.#{ext}")
        next unless baked
        results << baked.build_path
      end
      final = prepare_final(path, *results)
      minify(final) if bundle.minify?
      final
    end

    def replace_macros(source)
      source.gsub("\#{REDBUG_URL}", @url)
    end
  end
  
end