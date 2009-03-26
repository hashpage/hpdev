module HPDev

  class Repo

    def initialize(path, url, mode, kind)
      @repo = Grit::Repo.new(path)
      @url = url
      @mode = mode
      @kind = kind

      @widgets_url = url(mode, "widgets")
      @skins_url = url(mode, "skins")
      @code_url = url(mode, "code")
      @engine_url = url(mode, "code", "engine")
      @system_url = url(mode, "code", "system")
      @redbug_url = url(mode, "code", "redbug")
      @editor_url = url(mode, "code", "editor")
      @front_url = url(mode, "code", "front")
    end
    
    def replace_macros(source, url)
      res = replace_urls(source)
      res = res.gsub("\#{BASE_URL}", url)
    end

    def replace_urls(source)
      res = source.dup
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
    
    def collect_meta()
      res = @repo.git.remote({}, "show", "origin")
      unless res =~ /URL: (.*)$/
        raise RepoError.new("unable to retrieve origin/master in #{@repo.path}")
      end
      url = $1
      if url =~ /git@github\.com:([^\/]+)\/([^\/]+)\.git$/
        return {
          'description' => "private repo",
          'tags' => [],
          'origin' => url,
          'home' => '?'
        }
      end
      
      unless url =~ /git:\/\/github\.com\/([^\/]+)\/([^\/]+)\.git$/
        raise RepoError.new("unable to parse repo url: #{url}")
      end
      author = $1
      project = $2
      home = "http://github.com/#{author}/#{project}"
      
      project_human = project
      if project_human =~ /pb.-(.*)/
        project_human = $1
      end
      
      require 'open-uri'
      HP.logger.info("Fetching: #{home}")
      doc = open(home) { |f| Hpricot(f) }
      raise RepoError.new("unable to download: #{home}") unless doc
      
      desc = doc.search("//meta[@name='description']")[0]['content']
      raise RepoError.new("unable to parse description in #{doc}") unless desc

      tags = [author, project_human]
      if desc =~ /(.*)\[(.*)\]$/
        desc = $1
        tags = $2.split(',').map{|t| t.strip }
      end
      
      { 
        'description' => desc,
        'tags' => tags,
        'origin' => url,
        'home' => home
      }
    end

    def bake(dest=".")
      FileUtils.makedirs(dest)
      meta = collect_meta
      File.open(File.join(dest, "meta.yaml"), "w") do |f|
        f << meta.to_yaml
      end
      postprocess(bake_version("master", dest), meta)
      @repo.tags.each do |tag|
        postprocess(bake_version(tag.name, dest), meta)
      end
    end

    def bake_version(version="master", dest=".")
      @version = version
      basename = "#{version}.zip"
      filename = File.join(dest, basename)
      FileUtils.makedirs(File.dirname(filename))
      @repo.archive_to_file(version, nil, filename, "zip", "cat")
      outdir = File.join(File.dirname(filename), version)
      `unzip -o "#{filename}" -d "#{outdir}"`
      `rm "#{filename}"`
      outdir
    end
    
    def postprocess(dir, meta={})
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