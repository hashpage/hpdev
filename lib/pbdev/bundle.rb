# Copyright (c) 2008 Sprout Systems, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

require 'digest/md5'

module PBDev

  class Bundle
    attr_reader :bundle_name
    attr_reader :javascript_libs, :stylesheet_libs
    attr_reader :source_root, :build_root, :url_root, :index_root
    attr_reader :build_mode, :build_kind
    attr_reader :make_resources_relative
    attr_reader :use_digest_tokens
    
    def self.build_mode
      (@build_mode || :development).to_sym
    end

    def self.build_mode=(new_mode) 
      @build_mode = new_mode
    end

    def self.build_kind
      (@build_kind || :engine).to_sym
    end

    def self.build_kind=(new_kind) 
      @build_kind = new_kind
    end

    def minify?
      build_mode == :production
    end

    # Returns the root URL to the current library.
    def initialize(bundle_name, opts ={})

      @bundle_name = bundle_name.to_sym

      # javacript_libs:: External required libraries.
      @javascript_libs = opts[:javascript_libs] || opts[:js_libs] || []

      # stylesheet_libs:: External required stylesheet library
      @stylesheet_libs = opts[:stylesheet_libs] || opts[:css_libs] || []

      #  public_root::       The root directory accessible to the web browser.
      @public_root = normalize_path(opts[:public_root] || 'public')

      @make_resources_relative = opts[:resources_relative] || false

      #  url_prefix::        The prefix to put in front of all resource requests.
      @url_prefix = opts[:url_prefix]

      #  build_prefix::      The prefix to put in front of the built files directory.  Generally if you are using absolute paths you want your build_prefix to match the url_prefix.  If you are using relative paths, you don't want a build prefix.
      @build_prefix = opts[:build_prefix]

      #  index_prefix::      The prefix to put in front of all index.html request.
      @index_prefix = opts[:index_prefix] || opts[:index_at] || ''

      # The following properties are required for the build process but can be generated
      # automatically using other properties you specify:
      #  source_root::       The directory containing the source files
      @source_root = normalize_path(opts[:source_root])

      # The directory that should contain the built files.
      @build_root = normalize_path(opts[:build_root])

      # Note that if the resources are relative, we don't want to include a
      # '/' at the front.  Using nil will cause it to be removed during
      # compact.
      @url_root = opts[:url_root]

      #  index_root::        The root url that can be used to reach retrieve the index.html.
      @index_root = opts[:index_root]

      #  build_mode::        The build mode to use when combining resources.
      @build_mode = opts[:build_mode]

      @build_kind = opts[:build_kind]

      @use_digest_tokens = opts[:use_digest_tokens] || (@build_mode == :production)
      
      reload!
    end

    ######################################################
    ## RETRIEVING RESOURCES
    ##

    def sorted_stylesheet_entries(opts = {})
      entries = entries_for(:stylesheet, opts)
      BuildTools::ResourceBuilder.sort_entries_by_load_order(entries, self)
    end

    def sorted_javascript_entries(opts = {})
      entries = entries_for(:javascript, opts)
      BuildTools::JavaScriptResourceBuilder.sort_entries_by_load_order(entries, self)
    end

    def entries_for(resource_type, opts={})
      with_hidden = opts[:hidden] || :none

      mode = (opts[:build_mode] || build_mode).to_sym
      manifest = manifest_for(language, mode, platform)

      ret = manifest.entries_for(resource_type)

      case with_hidden
      when :none
        ret = ret.reject { |x| x.hidden }
      when :only
        ret = ret.reject { |x| !x.hidden }
      end
      return ret
    end

    def entry_for(resource_name, opts={})
      with_hidden = opts[:hidden] || :none

      mode = (opts[:build_mode] || build_mode).to_sym
      manifest = manifest_for(mode)

      ret = manifest.entry_for(resource_name)

      case with_hidden
      when :none
        ret = nil if ret && ret.hidden?
      when :only
        ret = nil unless ret && ret.hidden?
      end
      return ret
    end

    def entries(opts ={})
      with_hidden = opts[:hidden] || :none

      mode = (opts[:build_mode] || build_mode).to_sym
      manifest = manifest_for(mode)

      ret = manifest.entries

      case with_hidden
      when :none
        ret = ret.reject { |x| x.hidden }
      when :only
        ret = ret.reject { |x| !x.hidden }
      end
      return ret
    end

    # Does a deep search of the entries, looking for a resource that is a
    # close match of the specified resource.  This does not need to match the
    # filename exactly and it can omit the extension
    def find_resource_entry(filename, opts={}, seen=nil)
      extname = File.extname(filename)
      rootname = filename.gsub(/#{extname}$/,'')
      entry_extname = entry_rootname = nil

      ret = entries_for(:resource, opts.merge(:hidden => :none)).reject do |entry|
        entry_extname = File.extname(entry.filename)
        entry_rootname = entry.filename.gsub(/#{entry_extname}$/,'')

        ext_match = (extname.nil? || extname.size == 0) || (entry_extname == extname)
        !(ext_match && (/#{rootname}$/ =~ entry_rootname))
      end

      ret = ret.first

      if ret.nil?
        seen = Set.new if seen.nil?
        seen << self
        all_required_bundles.each do |bundle|
          next if seen.include?(bundle) # avoid recursion
          ret = @bundle.find_resource_entry(filename, opts, seen)
          return ret unless ret.nil?
        end
      end
      return ret
    end

    # Builds the passed array of entries.  If the entry is already built, then
    # this method does nothing unless force => true
    #
    # The exact action taken by this method varies by resource type.  Some
    # resources will simply be copied.  Others will actually be compiled.
    def build_entries(entries, opts={})

      with_hidden = opts[:hidden] || :none

      # First, start an "already seen" set.
      created_seen = @seen.nil?
      @seen ||= []

      # Now, process the entries, adding them to the seen set.
      entries.each do |entry|

        # skip if hidden, already seen, or already built (unless forced)
        if entry.hidden? && with_hidden == :none
          PB.logger.debug("~ Skipping Entry: #{entry.filename} because it is hidden") 
          next
        end

        if !entry.hidden? && with_hidden == :only
          PB.logger.debug("~ Skipping Entry: #{entry.filename} because it is not hidden") 
          next
        end

        # Nothing interesting to log here.
        next if @seen.include?(entry)
        @seen << entry

        # Do not build if file exists and source paths are not newer.
        if !opts[:force] && File.exists?(entry.build_path)
          source_mtime = entry.source_path_mtime
          if source_mtime && (File.mtime(entry.build_path) >= source_mtime)
            entry.fresh = false
            PB.logger.debug("~ Skipping Entry: #{entry.filename} because it has not changed") 
            next
          end
        end

        # OK, looks like this is ready to be built.
        # if the entry is served directly from source
        if entry.use_source_directly?
          PB.logger.debug("~ No Build Required: #{entry.filename} (will be served directly)")
        else
          PB.logger.debug("~ Building #{entry.type.to_s.capitalize}: #{entry.filename}")
          PBDev.send("build_#{entry.type}".to_sym, entry, self)
          entry.fresh = true
        end
      end

      # Clean up the seen set when we exit.
      @seen = nil if created_seen
    end

    # Easy singular form of build_entries().  Take same parameters except for a single entry instead of an array.
    def build_entry(entry, opts={})
      build_entries([entry], opts)
    end

    # This will perform a complete build
    def build()
      PB.logger.debug("~ Build Mode:  #{build_mode}")
      PB.logger.debug("~ Source Root: #{source_root}")
      PB.logger.debug("~ Build Root:  #{build_root}")
      build_entries(entries())
    end

    ######################################################
    ## MANIFESTS
    ##

    # Invoke this method whenever you think the bundle's contents on disk
    # might have changed this will throw away any cached information in
    # bundle.  This is generally a cheap operation so it is OK to call it
    # often, though it will be less performant overall.
    def reload!
      @manifests = {}
      @strings_hash = {}
    end

    def manifest_for(build_mode)
      manifest_key = [build_mode.to_s].join(':').to_sym
      @manifests[manifest_key] ||= BundleManifest.new(self, build_mode.to_sym)
    end

    protected

    def normalize_path(path)
      path
    end

  end

end