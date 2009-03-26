module HPDev
  
  class SkinRepo < Repo

    def postprocess(dir, meta={})
      url = @url+"/"+@version
      
      index = File.join(dir, "index.html")
      content = File.read(index)
      File.open(index, "w") do |f|
        f << replace_macros(content, url)
      end
      
      Dir.glob(File.join(dir, "**/*.css")) do |file|
        content = File.read(file)
        File.open(file, "w") do |f|
          f << replace_macros(content, url)
        end
      end
      
      dir
    end
  end

  class SkinCheckout < Checkout

    def serve(path, build_mode = :development)
      HP.logger.debug(path)
      resource_path = File.join(@path, path)
      return resource_path unless path=="index.html" 
      # the path is index.html
      content = File.read(resource_path)
      content = replace_macros(content)

      final_file = File.join(@temp, "_index.html")
      File.open(final_file, "w") do |f|
        f << replace_macros(content)
      end
      
      final_file
    end

  end
  
end