module HPDev
  
  class EditorRepo < Repo
    def postprocess(dir)
      url = @url+"/"+@version
      tempdir = File.join(dir, ".temp")
      wc = EditorCheckout.new(@mode, @kind, dir, tempdir, url)
      filename = wc.serve("editor.js")
      remove_intermediate(dir)
      Dir.chdir(dir) do
        `mv "#{filename}" editor.js`
        `rm -rf .temp`
      end
      dir
    end
  end

  class EditorCheckout < Checkout
    def serve(path)
      resource_path = File.join(@path, path)
      HP.logger.debug(resource_path)
      return resource_path unless path=="editor.js"
      bakein(path, "js", %w(tpl html css js), "HP.e={templates:{}};")
    end
  end
end