require 'fileutils'

PREFIX = 'openvpn'

`cp -r ../ics-openvpn/main/src .`
`cp -f ../ics-openvpn/main/build.gradle .`
`ln -sf ../ics-openvpn/main/lzo .`
`ln -sf ../ics-openvpn/main/openssl .`
`ln -sf ../ics-openvpn/main/ovpn3 .`
`ln -sf ../ics-openvpn/main/jni .`
`ln -sf ../ics-openvpn/main/misc .`
`ln -sf ../ics-openvpn/main/openvpn .`
`ln -sf ../ics-openvpn/main/snappy .`

`git --git-dir="../ics-openvpn/.git" describe HEAD > ics-openvpn-version`

FileUtils.mv 'src/main/res/layout/server_layout', 'src/main/res/layout/server_layout.xml'

def process(files)
  files.each do |file|
    text = File.read(file)
    processed = yield text
    File.open(file, 'w') { |file| file.puts processed }
  end
end

process Dir['src/main/res/values*/strings.xml'] do |text|
  text.gsub(/<string name="(?<name>.*?)">/, "<string name=\"#{PREFIX}_\\k<name>\">")
end

process Dir['src/main/res/**/arrays.xml'] do |text|
  text.gsub(/<string-array name="(?<name>.*?)">/, "<string-array name=\"#{PREFIX}_\\k<name>\">")
end

process ['src/main/res/values/untranslatable.xml'] do |text|
  text.gsub(/<string name="(?<name>.*?)"/, "<string name=\"#{PREFIX}_\\k<name>\"")
end

process ['src/main/res/values/untranslatable.xml'] do |text|
  text.gsub(/<string-array name="(?<name>.*?)"/, "<string-array name=\"#{PREFIX}_\\k<name>\"")
end

process ['src/main/res/values/attrs.xml'] do |text|
  text.gsub!(/<declare-styleable name="(?<name>.*?)"/, "<declare-styleable name=\"#{PREFIX}_\\k<name>\"")
  text.gsub!(/<attr name="(?<name>.*?)"/, "<attr name=\"#{PREFIX}_\\k<name>\"")

  text
end

process Dir['src/main/res/**/colours.xml'] do |text|
  text.gsub(/<color name="(?<name>.*?)">(?<value>.*?)<\/color>/, "<color name=\"#{PREFIX}_\\k<name>\">\\k<value></color>")
end

process Dir['src/main/res/**/dimens.xml'] do |text|
  text.gsub!(/<dimen name="(?<name>.*?)">(?<value>.*?)<\/dimen>/, "<dimen name=\"#{PREFIX}_\\k<name>\">\\k<value></dimen>")
  text.gsub!(/<bool name="(?<name>.*?)">(?<value>.*?)<\/bool>/, "<bool name=\"#{PREFIX}_\\k<name>\">\\k<value></bool>")

  text
end

process Dir['src/main/res/**/refs.xml'] do |text|
  text.gsub(/<drawable name="(?<name>.*?)">(?<value>.*?)<\/drawable>/, "<drawable name=\"#{PREFIX}_\\k<name>\">\\k<value></drawable>")
end

process Dir['src/main/res/**/styles.xml'] do |text|
  text.gsub(/<style name="/, "<style name=\"#{PREFIX}_")
end

process Dir['src/main/res/**/styles.xml'] do |text|
  text.gsub(/parent="blinkt/, "parent=\"#{PREFIX}_blinkt")
end

process Dir['src/main/res/**/styles.xml'] do |text|
  text.gsub(/<dimen name="(?<name>.*?)">(?<value>.*?)<\/dimen>/, "<dimen name=\"#{PREFIX}_\\k<name>\">\\k<value></dimen>")
end

# @color, @drawable, @+id, @string, @layout, etc
process Dir['src/main/res/**/*.xml'] + ['src/main/AndroidManifest.xml'] do |text|
  text.gsub(/(@\+?\w+?)\//, "\\1/#{PREFIX}_")
end

process Dir['src/main/res/layout*/*.xml'] do |text|
  text.gsub(/(blinkt:)/, "\\1#{PREFIX}_")
end

process %w(src/main/AndroidManifest.xml) do |text|
  text.gsub!(/android:minSdkVersion="\d+"/, 'android:minSdkVersion="14"')
  text.gsub!(/android:versionName=".+?"\s*/, '')
  text.gsub!(/android:versionCode=".+?"\s*/, '')
  text.gsub!(/android:installLocation=".+?"\s*/, '')
  
  # Leave permissions up to the app, not the lib
  text.gsub!(/<uses-permission.+?\/>/, '')
  # Same for supports-screens
  text.gsub!(/<supports-screens.+?\/>/m, '')

  # Remove <intent-filter>s
  # text.gsub!(/<activity(.+?[^\/])>(.+?)<\/activity>/m, '<activity\1 />')
  text.gsub!(/<intent-filter>(.+?)<\/intent-filter>/m, '')

  text
end

process %w(build.gradle) do |text|
  text.gsub!(/com\.android\.application/, 'com.android.library')
  text.gsub!(/mavenCentral/, 'jcenter')

  text
end

# Rename resource files
Dir['src/main/res/**/*.*'].each do |file|
  unless file.include? "/#{PREFIX}_"
    new_name = file.gsub(/([\w_]+\.[\w_]+)/, "#{PREFIX}_\\1")
    FileUtils.rm new_name if File.exists? new_name
    FileUtils.mv file, new_name
  end
end

process Dir['**/*.java'] do |text|
  text.gsub!(/id\.alias_certificate/, 'R.id.alias_certificate')

  # Replace resource ids
  text.gsub!(/([^\.])R\.(bool|string|layout|id|xml|menu|color|drawable|raw)\./, "\\1R.\\2.#{PREFIX}_")

  text.gsub!(/([^\.])R\.styleable\.(PagerSlidingTabStrip|FileSelectLayout)([^_])/, "\\1R.styleable.#{PREFIX}_\\2\\3")
  text.gsub!(/([^\.])R\.styleable\.(PagerSlidingTabStrip|FileSelectLayout)(_[\w])/, "\\1R.styleable.#{PREFIX}_\\2_#{PREFIX}\\3")
  # Very nasty hack to convert (some) switch statements into if statements
  text.gsub!(/    switch \(.+?\) \{(.+?)\n    \}/m) do |body|
    if body.include? 'case R.id.'
      body.gsub!(/switch \((.+?)\) \{/, 'int switchValue = \1;')
      body.gsub!(/(  break;\s+?)?  case (.+?)\:/, '} else if(switchValue == \2) {')
      body.gsub!(/(  break;\s+?)?  default\:/, '} else {')
      body.sub!(/^(\s+)\} else if/, '\1if')
      body.gsub!(/\n\s+break;/, '')
      body
    else
      body
    end
  end

  text
end
