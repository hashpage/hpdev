require 'digest/md5'

module PBDev
  
  class Checkout
    def initialize(mode, kind, path, temp, url)
      epath = File.expand_path(path)
      raise NoSuchPathError.new(epath) unless File.exists? epath
      @mode = mode
      @path = epath
      @temp = temp
      @url = url
      @kind = kind
      prepare_bundle()
    end
    
    def prepare_bundle()
      @bundle = Bundle.new("xxx", {
        :source_root => @path,
        :build_mode => @mode,
        :build_root => temp(),
        :build_kind => @kind
      })
      @bundle.build()
    end
    
    def serve(path)
      File.join(@path, path)
    end
    
    def temp(path = "")
      digest = Digest::MD5.hexdigest(self.class.name + @url + path)
      File.join(@temp, digest)
    end
    
    def final_path(path, *results)
      results = results.reject { |x| x.nil? }
      base = path
      results.each do |result|
        base << result.gsub(".", "_")
      end
      final = File.join(temp(base), "result.js")
    end
    
    def prepare_final(final, *results)
      results = results.reject { |x| x.nil? }
      FileUtils.makedirs(File.dirname(final))
      File.open(final, "w") do |f|
        results.each do |result|
          content = File.read(result)
          f << replace_macros(content) + "\n"
        end
      end
      final
    end

    def minify(path)
      yui_root = File.expand_path(File.join(File.dirname(__FILE__), '..', 'yui-compressor'))
      jar_path = File.join(yui_root, 'yuicompressor-2.4.2.jar')
      filecompress = "java -jar \"" + jar_path + "\" --charset utf-8 \"" + path + "\" -o \"" + path + "\""
      PB.logger.info('Compressing with YUI .... '+ path)
      res = `#{filecompress} 2>&1`
      if $?.exitstatus != 0
        PB.logger.fatal("!!!!YUI compressor failed, please check that your js code is valid and doesn't contain reserved statements like debugger;")
        PB.logger.fatal("!!!!Failed compressing ... "+ path)
        PB.logger.fatal(res)
        failed_path = File.join(File.dirname(path), "failed_"+File.basename(path))
        `mv "#{path}" "#{failed_path}"`
        raise YUICompressorError.new(failed_path + "\n\n" + res)
      end
    end
    
    def bakein(path, bundle=nil)
      bundle = @bundle unless bundle
      bundle.reload!
      results = []
      fresh = []
      %w(js css tpl html).each do |ext|
        baked = bundle.entry_for("baked_index.#{ext}")
        next unless baked
        bundle.build_entry(baked)
        results << baked.build_path
        fresh << baked.fresh
      end
      final_path = final_path(path, *results)
      if File.exists?(final_path) && !(fresh.any? {|x| x }) then
        PB.logger.debug("~ Skipping Entry: #{final_path} because it has not changed") 
        return final_path 
      end
      PB.logger.info("Baking #{@url}/#{path} ...")
      prepare_final(final_path, *results)
      minify(final_path) if bundle.minify?
      final_path
    end

  end
  
end