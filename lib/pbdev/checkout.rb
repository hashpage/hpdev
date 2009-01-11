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
      false
    end
    
  end
  
end