module PBDev
  
  class SkinRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      
      index = File.join(dir, "index.html")
      content = File.read(index)
      File.open(index, "w") do |f|
        f << replace_macros(content, url)
      end
      dir
    end
    
    def replace_macros(source, url)
      source.gsub("\#{SKIN_URL}", url)
    end
  end

  class SkinCheckout < Checkout
    def serve(path, build_mode = :development)
      PB.logger.debug(path)
      resource_path = File.join(@path, path)
      return resource_path unless path=="index.html" 
      # the path is index.html
      content = File.read(resource_path)
      content = replace_macros(content)

      final_file = File.join(@temp, "_index.html")
      File.open(final_file, "w") do |f|
        f << content
      end
      
      final_file
    end

    def replace_macros(source)
      source.gsub("\#{SKIN_URL}", @url)
    end
  end
  
end