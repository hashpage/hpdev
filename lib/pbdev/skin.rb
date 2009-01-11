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
      source.gsub("__SKIN_URL__", url)
    end
  end

  class SkinCheckout < Checkout
  end
  
end