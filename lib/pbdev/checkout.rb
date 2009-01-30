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
      
      @widgets_url = url(mode, "widgets")
      @skins_url = url(mode, "skins")
      @code_url = url(mode, "code")
      @engine_url = url(mode, "code", "engine")
      @system_url = url(mode, "code", "system")
      @redbug_url = url(mode, "code", "redbug")
      @editor_url = url(mode, "code", "editor")
      @front_url = url(mode, "code", "front")
      
      prepare_bundle()
    end
    
    def replace_macros(source)
      res = replace_urls(source)
    end
    
    def replace_urls(source)
      res = source.dup
      res.gsub!("\#{BASE_URL}", @url)
      res.gsub!("\#{WIDGETS_URL}", @widgets_url)
      res.gsub!("\#{SKINS_URL}", @skins_url)
      res.gsub!("\#{CODE_URL}", @code_url)
      res.gsub!("\#{SYSTEM_URL}", @system_url)
      res.gsub!("\#{ENGINE_URL}", @engine_url)
      res.gsub!("\#{REDBUG_URL}", @redbug_url)
      res.gsub!("\#{EDITOR_URL}", @editor_url)
      res.gsub!("\#{FRONT_URL}", @front_url)
      res
    end
    
    def prepare_bundle()
      @bundle = Bundle.new("index", {
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
    
    def final_path(path, ext, *results)
      results = results.reject { |x| x.nil? }
      base = path.dup
      results.each do |result|
        base << result.gsub(".", "_")
      end
      File.join(temp(base), "result."+ext)
    end
    
    def prepare_final(final, prolog, *results)
      results = results.reject { |x| x.nil? }
      FileUtils.makedirs(File.dirname(final))
      File.open(final, "w") do |f|
        f << prolog
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
      PB.logger.info('  crunching with YUI Compressor ...')
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
    
    def bakein(path, ext="js", what = %w(tpl html css js), prolog="", bundle=nil)
      bundle = @bundle unless bundle
      bundle.reload!
      results = []
      fresh = []
      what.each do |ext|
        baked = bundle.entry_for("baked_index.#{ext}")
        next unless baked
        bundle.build_entry(baked)
        results << baked.build_path
        fresh << baked.fresh
      end
      final_path = final_path(path, ext, *results)
      if File.exists?(final_path) && !(fresh.any? {|x| x }) then
        PB.logger.debug("~ Skipping Entry: #{final_path} because it has not changed") 
        return final_path 
      end
      PB.logger.info("Baking #{@url}/#{path} ...")
      prepare_final(final_path, prolog, *results)
      minify(final_path) if bundle.minify?
      final_path
    end
  end
  
end