#!env ruby
require 'builder'

docset = ARGV[0]

o = Marshal.load(File.open('.yardoc/object_types'))
FileUtils.mkdir_p("#{docset}.docset/Contents/Resources")
FileUtils.remove_dir("#{docset}.docset/Contents/Resources/Documents") if File.exists? "#{docset}.docset/Contents/Resources/Documents"
FileUtils.cp_r('doc', "#{docset}.docset/Contents/Resources/Documents")

File.open("#{docset}.docset/Contents/Info.plist", 'w') do |file|
  info = <<-INFO
  <!DOCTYPE plist SYSTEM "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleIdentifier</key>
        <string>#{docset.downcase}</string>
        <key>CFBundleName</key>
        <string>#{docset}</string>
        <key>DocSetPlatformFamily</key>
        <string>appledoc</string>
        <key>isJavaScriptEnabled</key>
        <true/>
      </dict>
    </plist>
  INFO
  file.write info
end

File.open("#{docset}.docset/Contents/Resources/Nodes.xml", 'w') do |file|
  nodes = <<-NODES
  <DocSetNodes version="1.0">
    <TOC>
      <Node type="folder">
        <Name>#{docset} documentation</Name>
        <Path>index.html</Path>
      </Node>
    </TOC>
  </DocSetNodes>
  NODES
  file.write nodes
end

File.open("#{docset}.docset/Contents/Resources/Tokens.xml", 'w') do |file|
  xml = Builder::XmlMarkup.new(indent: 2, target: file)
  xml.instruct! :xml, encoding: 'UTF-8'
  xml.Tokens({version: "1.0"}) do |tokens|
    o[:module].sort.each do |cls|
      tokens.File({path: "#{cls.gsub('::', '/')}.html"}) do |file|
        file.Token do |token|
          token.TokenIdentifier "//apple_ref/cpp/cat/#{cls.split('::').last}"
        end
      end
    end
    o[:class].sort.each do |cls|
      tokens.File({path: "#{cls.gsub('::', '/')}.html"}) do |file|
        file.Token do |token|
          token.TokenIdentifier "//apple_ref/cpp/cl/#{cls.split('::').last}"
        end
      end
    end
    o[:method].sort.each do |cls|
      if cls.include? '#'
        tokens.File({path: "#{cls.gsub('::', '/').sub('#', '.html#')}-instance_method"}) do |file|
          file.Token do |token|
            token.TokenIdentifier "//apple_ref/cpp/clm/#{cls.split('::').last.sub('#', '.')}"
          end
        end
      else
        tokens.File({path: "#{cls.gsub('::', '/').sub('.', '.html#')}-class_method"}) do |file|
          file.Token do |token|
            token.TokenIdentifier "//apple_ref/cpp/clm/#{cls.split('::').last}"
          end
        end
      end
    end
    o[:constant].sort.each do |cls|
      tokens.File({path: "#{cls.gsub('::', '/').sub(/(.*)\/([A-Z0-9]+$)/, '\\1.html#\\2')}-constant"}) do |file|
        file.Token do |token|
          token.TokenIdentifier "//apple_ref/cpp/clconst/#{cls.split('::').last}"
        end
      end
    end
  end
end

`/Applications/Xcode.app/Contents/Developer/usr/bin/docsetutil index #{docset}.docset`
File.delete "#{docset}.tgz" if File.exists? "#{docset}.tgz"
`tar --exclude='.DS_Store' -czf #{docset}.tgz #{docset}.docset`
