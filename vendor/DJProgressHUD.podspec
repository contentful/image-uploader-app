Pod::Spec.new do |s|
  s.name             = "DJProgressHUD"
  s.version          = "0.0.1"
  s.summary          = "Progress and Activity HUD for OS X."
  s.homepage         = "https://github.com/danielmj/DJProgressHUD_OSX"
  s.license          = { :type => 'GPL', :file => 'LICENSE.txt' }
  s.author           = { "Daniel Jackson" => "http://www.danmjacks.com/" }
  s.source           = { :git => "https://github.com/danielmj/DJProgressHUD_OSX.git",
                         :commit => '988334280ea95a5ef2640deebab5663b5fb24f7f' }

  s.platform = :osx, '10.7'
  s.requires_arc = true
  s.source_files = 'DJProgressHUD'
end
