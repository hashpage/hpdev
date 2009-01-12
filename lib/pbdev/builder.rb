# Copyright (c) 2008 Sprout Systems, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

module PBDev

  # The ResourceBuilder can combine all of the source files listed in the 
  # passed entry including some basic pre-processing.  The JavaScriptBuilder 
  # extends this to do some JavaScript specific rewriting of URLs, etc. as 
  # well.
  #
  # The ResourceBuilder knows how
  class ResourceBuilder

    attr_reader :filenames
    attr_reader :bundle

    # utility method you can call to get the items sorted by load order
    def self.sort_entries_by_load_order(entries, bundle)
      filenames = entries.map { |e| e.filename }
      hashed = {}
      entries.each { |e| hashed[e.filename] = e }

      sorted = self.new(filenames, bundle).required
      sorted.map { |filename| hashed[filename] }
    end

    def initialize(filenames, bundle)
      @filenames = filenames
      @bundle = bundle
    end

    # simply returns the filenames in the order that they were required
    def required
      lines = []; required = []
      while filename = next_filename
        lines, required = _build_one(filename, lines, required, true)
      end
      return lines
    end

    # actually perform the build. Returns the compiled resource as a single string.
    def build
      lines = []
      required = []

      while filename = next_filename
        lines, required = _build_one(filename, lines, required)
      end

      return join(lines)
    end

    def join(lines)
      lines.join
    end

    def rewrite_inline_code(line, filename)
      # TODO: support static_url in the future
      #      line.gsub(/static_url\([\'\"](.+?)[\'\"]\)/) do | rsrc |
      #        entry = bundle.find_resource_entry($1, :language => language)
      #        static_url(entry.nil? ? '' : entry.cacheable_url)
      #      end
      line
    end

    def _build_one(filename, lines, required, link_only = false)
      return [lines, required] if required.include?(filename)
      required << filename

      entry = bundle.entry_for(filename, :hidden => :include)
      if entry.nil?
        puts "WARNING: Could not find require file: #{filename}"
        return [lines, required]
      end

      file_lines = []
      io = (entry.source_path.nil? || !File.exists?(entry.source_path)) ? [] : File.new(entry.source_path)
      io.each do | line |

        # check for requires. Only follow a require if the require is in the list of filenames.
        required_file = _require_for(filename, line)
        if required_file && filenames.include?(required_file)
          lines, required = _build_one(required_file, lines, required, link_only)
        end

        file_lines << rewrite_inline_code(line, filename) unless link_only
      end

      # The list of already required filenames is slightly out of order from
      # the actual load order.  Instead, we use the lines array to hold the
      # list of filenames as they are processed.
      if link_only
        lines << filename
      elsif file_lines.size > 0
#        if entry.ext == "sass"
#          PB.logger.fatal("TODO sass")
#          #           file_lines = [ PBDev::Renderers::Sass.compile(entry, file_lines.join()) ]
#        end
        lines += _process_file_lines(file_lines, filename)
      end

      [lines, required]
    end

    def _process_file_lines(lines, filename)
      result = []
      result << "\n\n/* " << filename << " ----------------------------------------------------- */\n\n"
      result << lines
      result
    end

    def next_filename
      filenames.delete(filenames.first)
    end

    # overridden by subclass to handle static_url() in a language specific way.
    def static_url(url); "url('#{url}')"; end

    # check line for required() pattern.  understands JS and CSS.
    def _require_for(filename,line)
      new_file = line.scan(/require\s*\(\s*['"](.*)(\.(js|css|sass))?['"]\s*\)/)
      ret = (new_file.size > 0) ? new_file.first.first : nil
      ret.nil? ? nil : filename_for_require(ret)
    end

    def filename_for_require(ret)
      filenames.include?("#{ret}.css") ? "#{ret}.css" : "#{ret}.sass"
    end
    
    def _target()
      return "" if bundle.build_kind==:engine 
      ".widgets['\#{WIDGET_URL}'].prototype"
    end
  end

  class JavaScriptResourceBuilder < ResourceBuilder

    def rewrite_inline_code(line, filename)
      if line.match(/sc_super\(\s*\)/)
        line = line.gsub(/sc_super\(\s*\)/, 'arguments.callee.base.apply(this,arguments)')
      end
      super(line, filename)
    end

    def static_url(url); "'#{url}'"; end
    def filename_for_require(ret); "#{ret}.js"; end
  end

  class CSSResourceBuilder < ResourceBuilder

    def join(lines)
      if bundle.minify?
        res = PBDev::CSSPacker.new.compress(lines.join)
      else
        res = lines.join
      end

      result = ""
      result << "\n\n/* " << "baked css files" << " ----------------------------------------------------- */\n\n"
      result << "PB#{_target}.css = '\\\n"
      result << escapejs(res)
      result << "';\n\n"
      result
    end

    def _process_file_lines(lines, filename)
      result = []
      result << lines << "\n"
      result
    end

    def static_url(url); "'#{url}'"; end
    def filename_for_require(ret); "#{ret}.css"; end
  end

  class TemplateResourceBuilder < ResourceBuilder

    def join(lines)
      lines.join
    end

    def _process_file_lines(lines, filename)
      result = []
      result << "\n\n/* " << filename << " ----------------------------------------------------- */\n\n"
      sanitized_name = File.basename(filename, ".tpl").gsub(/[\*\. -!&^\(\)\[\]]/, "_")
      result << "PB#{_target}.templates['#{sanitized_name}'] = '\\\n"
      lines.each do |line|
        line.strip! if bundle.minify?
        result << escapejs(line)
      end
      result << "';\n\n"
      result
    end

    def static_url(url); "#{url}"; end
    def filename_for_require(ret); "#{ret}.tpl"; end
  end

  class HtmlResourceBuilder < ResourceBuilder

    def join(lines)
      if bundle.minify?
        res = lines.join # TODO: minify HTML
      else
        res = lines.join
      end
      
      

      result = ""
      result << "\n\n/* " << "baked html files" << " ----------------------------------------------------- */\n\n"
      result << "PB#{_target}.html = '\\\n"
      result << escapejs(res)
      result << "';\n\n"
      result
    end

    def _process_file_lines(lines, filename)
      result = []
      result << lines << "\n"
      result
    end

    def static_url(url); "'#{url}'"; end
    def filename_for_require(ret); "#{ret}.html"; end
  end

  # ------------------------------------------------------------------------------------------------
  
  def self.build_template(entry, bundle)
    filenames = entry.composite? ? entry.composite_filenames : [entry.filename]
    builder = TemplateResourceBuilder.new(filenames, bundle)
    if output = builder.build
      FileUtils.mkdir_p(File.dirname(entry.build_path))
      f = File.open(entry.build_path, 'w')
      f.write(output)
      f.close
    end
  end

  def self.build_html(entry, bundle)
    filenames = entry.composite? ? entry.composite_filenames : [entry.filename]
    builder = HtmlResourceBuilder.new(filenames, bundle)
    if output = builder.build
      FileUtils.mkdir_p(File.dirname(entry.build_path))
      f = File.open(entry.build_path, 'w')
      f.write(output)
      f.close
    end
  end

  def self.build_stylesheet(entry, bundle)
    filenames = entry.composite? ? entry.composite_filenames : [entry.filename]
    builder = CSSResourceBuilder.new(filenames, bundle)
    if output = builder.build
      FileUtils.mkdir_p(File.dirname(entry.build_path))
      f = File.open(entry.build_path, 'w')
      f.write(output)
      f.close
    end
  end

  def self.build_javascript(entry, bundle)
    filenames = entry.composite? ? entry.composite_filenames : [entry.filename]
    builder = JavaScriptResourceBuilder.new(filenames, bundle)
    if output = builder.build
      FileUtils.mkdir_p(File.dirname(entry.build_path))
      f = File.open(entry.build_path, 'w')
      f.write(output)
      f.close
    end
  end

end