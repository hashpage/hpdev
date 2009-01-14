module PBDev
  
  class Repo
    def initialize(path, url, mode, kind)
      @repo = Grit::Repo.new(path)
      @url = url
      @mode = mode
      @kind = kind
    end
    
    def bake(dest=".")
      postprocess(bake_version("master", dest))
      @repo.tags.each do |tag|
        postprocess(bake_version(tag.name, dest))
      end
    end

    def bake_version(version="master", dest=".")
      @version = version
      base = File.basename(@repo.working_dir)
      base = base[4..-1] if base=~/^pb.-/ 
      basename = "#{version}.zip"
      filename = File.join(dest, basename)
      FileUtils.makedirs(File.dirname(filename))
      @repo.archive_to_file(version, nil, filename, "zip", "| cat")
      outdir = File.join(File.dirname(filename), version)
      `unzip -o "#{filename}" -d "#{outdir}"`
      `rm "#{filename}"`
      outdir
    end
    
    def postprocess(dir)
      dir
    end
    
    def remove_intermediate(dir)
      ["js", "css", "tpl", "html"].each do |ext|
        Dir.glob(File.join(dir, "**/*.#{ext}")) do |file|
          File.unlink(file)
        end
      end
      
      remove_empty_directories(dir)
    end
    
    def remove_empty_directories(dir)
      raise "paranoia" if dir.size<10
      `find "#{dir}" -depth -empty -type d -exec rmdir {} \\;`
    end

  end
  
end