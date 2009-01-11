module PBDev
  
  class WidgetRepo < Repo
    def postprocess(path)
    end
  end
  
  class WidgetCheckout < Checkout
    def serve(path, build_mode = :development)
      ext = File.extname(path)
      basename = File.basename(path, ".js")
      resource_path = File.join(@path, path)
      raise ResourceNotFoundError.new(resource_path) unless File.exists?(resource_path)
      raise IntermediateFileError.new(resource_path) if ext==".tpl" || ext==".html" || ext==".css" || (ext==".js" && basename!="index")
      return resource_path unless ext==".js" # images and other static files
      # path is index.js

      bundle = Bundle.new(path, {
        :source_root => @path,
        :build_mode => build_mode,
        :build_root => @temp
      })
      bundle.build()
      baked_js = bundle.entry_for("baked_index.js")
      baked_css = bundle.entry_for("baked_index.css")
      baked_tpl = bundle.entry_for("baked_index.tpl")

      path_js = baked_js.build_path if baked_js
      path_css = baked_css.build_path if baked_css
      path_tpl = baked_tpl.build_path if baked_tpl

      final_path = prepare_final(path_js, path_css, path_tpl, build_mode)

      if bundle.minify?
        yui_root = File.expand_path(File.join(File.dirname(__FILE__), '..', 'yui-compressor'))
        jar_path = File.join(yui_root, 'yuicompressor-2.4.2.jar')
        filecompress = "java -jar \"" + jar_path + "\" --charset utf-8 \"" + final_path + "\" -o \"" + final_path + "\""
        puts 'Compressing with YUI .... '+ final_path
        puts `#{filecompress}`
        if $?.exitstatus != 0
          PB.logger.fatal("!!!!YUI compressor failed, please check that your js code is valid and doesn't contain reserved statements like debugger;")
          PB.logger.fatal("!!!!Failed compressing ... "+ final_path)
        end
      end

      final_path
    end

    def prepare_final(path_js, path_css, path_tpl, build_mode)
      base = File.basename(path_js, ".js") + File.basename(path_css, ".css") + File.basename(path_tpl, ".tpl") + ".js"
      final_file = File.join(@temp, base)

      js_source = File.read(path_js)
      tpl_source = File.read(path_tpl)
      css_source = File.read(path_css)

      File.open(final_file, "w") do |f|
        f << replace_macros(js_source)
        f << "\n"
        f << replace_macros(tpl_source)
        f << "\n"
        f << replace_macros(css_source)
      end

      final_file
    end

    def replace_macros(source)
      source.gsub("__WIDGET_URL__", @url)
    end
  end
end