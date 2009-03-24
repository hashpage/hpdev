$cache = {}

def produce(checkout, path)
  begin
    file_path = checkout.serve(path)
  rescue IntermediateFileError
    throw :halt, [404, 'Requested intermediate resource. This resource won\'t be present on production. See index.js instead.']
  rescue ResourceNotFoundError => e
    throw :halt, [404, 'resource not found']
  rescue YUICompressorError => e
    throw :halt, [404, 'YUI compressor error: ' + $!.message]
  end
end

def serve(mod, path)
  url = "#{$server_url}/code/#{mod}/master"
  checkout = $cache[url.to_sym]
  unless checkout
    begin
      resource_path = File.join($workspace, mod)
      checkout = $cache[url.to_sym] = eval(mod.capitalize+"Checkout").new($mode, mod.to_sym, resource_path, File.join($workspace, "temp"), url)
    rescue NoSuchPathError
      throw :halt, [404, 'file not found']
    end
  end
  file_path = produce(checkout, path)
  send_file(file_path, {
    :disposition => 'inline'
  })
end

def serve_widget(path, name, author, kind)
  case kind
  when "widgets"
    klass = WidgetCheckout
    prefix = "hpw"
  when "skins"
    klass = SkinCheckout
    prefix = "hps"
  else
    throw :halt, [404, 'bad resource kind']
  end

  url = "#{$server_url}/#{kind}/#{author}/#{name}/master"
  checkout = $cache[url.to_sym]
  unless checkout
    temp = File.join($workspace, "temp")
    begin 
      resource_path = File.join($workspace, kind, author, name)
      checkout = $cache[url.to_sym] = klass.new($mode, :widget, resource_path, temp, url)
    rescue NoSuchPathError
      if name.index("-") then
        # try without prefix
        name = name.split("-")[1..-1].join("-")
      else
        # try with prefix
        name = prefix + "-" + name
      end
      begin
        resource_path = File.join($workspace, kind, author, name)
        checkout = $cache[url.to_sym] = klass.new($mode, :widget, resource_path, temp, url)
      rescue NoSuchPathError
        throw :halt, [404, 'file not found']
      end
    end
  end
  file_path = produce(checkout, path)
  return send_file(file_path, {
    :disposition => 'inline'
  })
end