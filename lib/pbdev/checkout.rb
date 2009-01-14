require 'digest/md5'

module PBDev
  
  class Checkout
    def initialize(path, temp, url)
      epath = File.expand_path(path)
      raise NoSuchPathError.new(epath) unless File.exists? epath
      @path = epath
      @temp = temp
      @url = url
    end
    
    def serve(path)
      File.join(@path, path)
    end
    
    def temp(path)
      digest = Digest::MD5.hexdigest(self.class.name + @url + path)
      File.join(@temp, digest)
    end
    
    def prepare_final(path, *results)
      results = results.reject { |x| x.nil? }
      base = path
      results.each do |result|
        base << result.gsub(".", "_")
      end
      final = File.join(temp(base), "result.js")
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
      puts 'Compressing with YUI .... '+ path
      puts `#{filecompress}`
      if $?.exitstatus != 0
        PB.logger.fatal("!!!!YUI compressor failed, please check that your js code is valid and doesn't contain reserved statements like debugger;")
        PB.logger.fatal("!!!!Failed compressing ... "+ path)
      end
    end

  end
  
end