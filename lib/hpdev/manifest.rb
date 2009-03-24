# Copyright (c) 2008 Sprout Systems, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

require 'yaml'
require 'digest/md5'

module PBDev

  # A Bundle Manifest describes all of the resources in a bundle, including
  # mapping their source paths, destination paths, and urls.
  class BundleManifest

    CACHED_TYPES    = [:javascript, :stylesheet, :template, :html]
    SYMLINKED_TYPES = []

    NORMALIZED_TYPE_EXTENSIONS = {
      :stylesheet => { :sass => :css }
    }

    attr_reader :bundle, :build_mode

    def initialize(bundle, build_mode)
      @bundle = bundle
      @build_mode = build_mode
      @entries_by_type = {}
      @entries_by_filename = {}
      build!
    end

    def bundle_name
      bundle.nil? ? nil : bundle.bundle_name
    end

    def entries
      @entries_by_filename.values
    end

    def entries_for(resource_type)
      @entries_by_type[resource_type] || []
    end

    def entry_for(resource_name)
      @entries_by_filename[resource_name] || nil
    end

    def to_a
      @entries_by_filename.values.map { |x| x.to_hash }
    end

    def to_hash
      @entries_by_type
    end

    def to_s
      @entries_by_filename.to_yaml
    end

    protected

    def build!
      entries = catalog_entries
      working = []

      if self.build_mode == :development
        (entries[:javascript] ||= []).each do | entry |
          setup_timestamp_token(entry)
        end

        (entries[:stylesheet] ||= []).each do | entry |
          setup_timestamp_token(entry)
        end
      end

      if (working = entries[:javascript]) && working.size>0
        entry = build_entry_for('baked_index.js', :javascript, working, true)
        setup_timestamp_token(entry) if self.build_mode == :development
        working << entry
      end

      if (working = entries[:stylesheet]) && working.size>0
        entry = build_entry_for('baked_index.css', :stylesheet, working, true)
        setup_timestamp_token(entry) if self.build_mode == :development
        working << entry
      end

      if (working = entries[:template]) && working.size>0
        entry = build_entry_for('baked_index.tpl', :template, working, true)
        setup_timestamp_token(entry) if self.build_mode == :development
        working << entry
      end

      if (working = entries[:html]) && working.size>0
        entry = build_entry_for('baked_index.html', :html, working, true)
        setup_timestamp_token(entry) if self.build_mode == :development
        working << entry
      end

      @entries_by_type = entries
      @entries_by_filenames = {}
      entries.values.flatten.each do |e|
        @entries_by_filename[e.filename] = e
      end
    end

    def catalog_entries
      entries = {}
      Dir.chdir(bundle.source_root) do
        Dir.glob(File.join('**','*')).each do |src_path|
          next if (src_type = type_of(src_path)) == :skip
          entry = build_entry_for(src_path, src_type)
          entry_key = entry.filename
          entries[entry_key] = entry
        end
      end
      ret = {}
      entries.values.each { |entry| (ret[entry.type] ||= []) << entry }
      return ret
    end

    def type_of(src_path)
      return :skip if File.directory?(src_path)
      case src_path
      when /\.rhtml$/
        :html
      when /\.html.erb$/
        :html
      when /\.haml$/
        :html
      when /\.html$/
        :html
      when /\.css$/
        :stylesheet
      when /\.sass$/
        :stylesheet
      when /\.js$/
        :javascript
      when /\.tpl$/
        :template
      else
        :skip
      end
    end

    # Build an entry for the resource at the named src_path (relative to the
    # source_root) This should assume we are in going to simply build each
    # resource into the build root without combining files, but not using our
    # _src symlink magic.
    #
    # +Params+
    #
    # src_path:: the source path, relative to the bunlde.source_root
    # src_type:: the detected source type (from type_of())
    # composite:: Array of entries that should be combined to form this or nil
    # hide_composite:: Makes composit entries hidden if !composite.nil?
    #
    # +Returns: Entry
    #
    def build_entry_for(src_path, src_type, composite=nil, hide_composite = true)
      ret = ManifestEntry.new
      ret.ext = File.extname(src_path)[1..-1] || '' # easy stuff
      ret.type = src_type
      ret.original_path = src_path
      ret.hidden = false
      ret.use_digest_tokens = bundle.use_digest_tokens
      ret.filename = src_path
      ret.source_path = composite.nil? ? File.join(bundle.source_root, src_path) : nil
      unless composite.nil?
        composite.each { |x| x.hidden = true } if hide_composite

        # IMPORTANT:  The array of composite entries passed in here can come
        # directly from the entries hash, which will later be updated to
        # include the composite entry (ret) itself.  Dup the array here to
        # make sure the list of composites maintained here does not change.
        ret.composite = composite.dup
      end

      # PREPARE BUILD_PATH and URL
      url_root = bundle.url_root

      # Setup special cases.  Certain types of files are processed and then
      # cached in development mode (i.e. JS + CSS).  Other resources are
      # simply served up directly without any processing or building.  See
      # constants for types.
      cache_link = nil
      use_source_directly = false
      if (self.build_mode == :development)
        cache_link = '_cache' if CACHED_TYPES.include?(src_type)
        use_source_directly = true if SYMLINKED_TYPES.include?(src_type)
      end

      # If this resource should be served directly, setup both the build_path
      # and URL to point to a special URL that maps directly to the resource.
      # This is only useful in development mode
      ret.use_source_directly = use_source_directly
      if use_source_directly
        path_parts = [bundle.build_root, '_src', src_path]
        ret.build_path = File.join(*(path_parts.compact))
        path_parts[0] = url_root
        ret.url = path_parts.compact.join('/')

      # If the resource is not served directly, then calculate the actual
      # build path and URL for production mode.  
      else
        path_parts = [bundle.build_root, ret.filename]
        ret.build_path = File.join(*path_parts.compact)

        path_parts[0] = url_root
        ret.url = path_parts.compact.join('/')

        path_parts[2] = 'current' # create path to "current" build
        ret.current_url = path_parts.compact.join('/')
      end

      # Convert the input source type an output type.
      if sub_type = NORMALIZED_TYPE_EXTENSIONS[ret.type]
        sub_type.each do | matcher, ext |
          matcher = /\.#{matcher.to_s}$/; ext = ".#{ext.to_s}"
          ret.build_path.sub!(matcher, ext)
          ret.url.sub!(matcher, ext)
        end
      end

      return ret
    end

    # Lookup the timestamp on the source path and interpolate that into the
    # filename URL and build path.  This should only be called on entries
    # that are to be cached (in development mode)
    def setup_timestamp_token(entry)
      timestamp = bundle.use_digest_tokens ? entry.digest : entry.timestamp

      # add timestamp or digest to URL
      extname = File.extname(entry.url)
      entry.url.gsub!(/#{extname}$/,"-#{timestamp}#{extname}")

      # add timestamp or digest to build path
      extname = File.extname(entry.build_path)
      entry.build_path.gsub!(/#{extname}$/,"-#{timestamp}#{extname}")
    end
  end

  # describes a single entry in the Manifest:
  #
  # filename::     relative path
  # ext::          the file extension
  # source_path:: absolute paths into source that will comprise this resource
  # url::          the url that should be used to reference this resource in the current build mode.
  # current_url::  the url that can be used to reference this resource, substituting "current" for a build number
  # build_path::   absolute path to the compiled resource
  # type::         the top-level category
  # original_path:: save the original path used to build this entry
  # hidden::       if true, this entry is needed internally, but otherwise should not be used
  # use_source_directly::  if true, then this entry should be handled via the build symlink
  # composite::    If set, this will contain the filenames of other resources that should be combined to form this resource.
  # bundle:: the owner bundle for this entry
  #
  class ManifestEntry
    attr_accessor :filename, :ext, :source_path, :url, :build_path, :type, :original_path, :hidden, :use_source_directly, :use_digest_tokens, :current_url, :fresh

    def to_hash
      ret = {}
      self.members.zip(self.values).each { |p| ret[p[0]] = p[1] }
      ret.symbolize_keys
    end

    def composite; @composite; end
    def composite=(ary); @composite=ary; end

    def hidden?; !!hidden; end
    def use_source_directly?; !!use_source_directly; end
    def composite?; !!composite; end

    # Returns true if this entry can be cached even in development mode.
    def cacheable?
      !composite?
    end

    def composite_filenames
      @composite_filenames ||= (composite || []).map { |x| x.filename }
    end

    # Returns the mtime of the source_path.  If this entry is a composite
    # return the latest mtime of the items or if the source file does not
    # exist, returns nil
    def source_path_mtime
      return @source_path_mtime unless @source_path_mtime.nil?

      if composite?
        mtimes = (composite || []).map { |x| x.source_path_mtime }
        ret = mtimes.compact.sort.last
      else
        ret = (File.exists?(source_path)) ? File.mtime(source_path) : nil
      end
      return @source_path_mtime = ret
    end

    # Returns a timestamp based on the source_path_mtime.  If
    # source_path_mtime is nil, always returns a new timestamp
    def timestamp
      (source_path_mtime || Time.now).to_i.to_s
    end

    # Returns an MD5::digest of the file.  If the file is composite, returns
    # the MD5 digest of all the composite files.
    def digest
      return @digest unless @digest.nil?

      if composite?
        digests = (composite || []).map { |x| x.digest }
        ret = Digest::SHA1.hexdigest(digests.join)
      else
        ret = (File.exists?(source_path)) ? Digest::SHA1.hexdigest(File.read(source_path)) : '0000'
      end
      @digest = ret
    end

    # Returns the content type for this entry.  Based on a set of MIME_TYPES
    # borrowed from Rack
    def content_type
      MIME_TYPES[File.extname(build_path)[1..-1]] || 'text/plain'
    end

    # Returns a URL that takes into account caching requirements.
    def cacheable_url
      url
    end

    # :stopdoc:
    # From WEBrick.
    MIME_TYPES = {
      "ai"    => "application/postscript",
      "asc"   => "text/plain",
      "avi"   => "video/x-msvideo",
      "bin"   => "application/octet-stream",
      "bmp"   => "image/bmp",
      "class" => "application/octet-stream",
      "cer"   => "application/pkix-cert",
      "crl"   => "application/pkix-crl",
      "crt"   => "application/x-x509-ca-cert",
     #"crl"   => "application/x-pkcs7-crl",
      "css"   => "text/css",
      "dms"   => "application/octet-stream",
      "doc"   => "application/msword",
      "dvi"   => "application/x-dvi",
      "eps"   => "application/postscript",
      "etx"   => "text/x-setext",
      "exe"   => "application/octet-stream",
      "gif"   => "image/gif",
      "htm"   => "text/html",
      "html"  => "text/html",
      "rhtml" => "text/html",
      "jpe"   => "image/jpeg",
      "jpeg"  => "image/jpeg",
      "jpg"   => "image/jpeg",
      "lha"   => "application/octet-stream",
      "lzh"   => "application/octet-stream",
      "mov"   => "video/quicktime",
      "mpe"   => "video/mpeg",
      "mpeg"  => "video/mpeg",
      "mpg"   => "video/mpeg",
      "pbm"   => "image/x-portable-bitmap",
      "pdf"   => "application/pdf",
      "pgm"   => "image/x-portable-graymap",
      "png"   => "image/png",
      "pnm"   => "image/x-portable-anymap",
      "ppm"   => "image/x-portable-pixmap",
      "ppt"   => "application/vnd.ms-powerpoint",
      "ps"    => "application/postscript",
      "qt"    => "video/quicktime",
      "ras"   => "image/x-cmu-raster",
      "rb"    => "text/plain",
      "rd"    => "text/plain",
      "rtf"   => "application/rtf",
      "sgm"   => "text/sgml",
      "sgml"  => "text/sgml",
      "tif"   => "image/tiff",
      "tiff"  => "image/tiff",
      "txt"   => "text/plain",
      "xbm"   => "image/x-xbitmap",
      "xls"   => "application/vnd.ms-excel",
      "xml"   => "text/xml",
      "xpm"   => "image/x-xpixmap",
      "xwd"   => "image/x-xwindowdump",
      "zip"   => "application/zip",
      "js"    => "text/javascript",
      "json"  => "text/json"
    }
    # :startdoc:

  end

end
