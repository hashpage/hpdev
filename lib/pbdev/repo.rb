module PBDev
  
  class Repo
    def initialize(path)
      @repo = Grit::Repo.new(path)
    end
    
    def bake(dest=".", author=".")
      postprocess(bake_version("master", dest, author))
      @repo.tags.each do |tag|
        postprocess(bake_version(tag.name, dest, author))
      end
    end

    def bake_version(version="master", dest=".", author=".")
      base = File.basename(@repo.working_dir)
      base = base[4..-1] if base=~/^pb.-/ 
      basename = "#{base}~#{version}.zip"
      filename = File.join(dest, author, basename)
      FileUtils.makedirs(File.dirname(filename))
      @repo.archive_to_file(version, nil, filename, "zip", "| cat")
      filename
    end
    
    def postprocess(path)
      path
    end

  end
  
end