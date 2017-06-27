Pod::Spec.new do |s|

  s.name         = "Rexxar"
  s.version      = "0.2.4"
  s.license      = { :type => 'MIT', :text => 'LICENSE' }

  s.summary      = "Rexxar Hybrid Framework"
  s.description  = "Rexxar is Douban Hybrid Framework. By Rexxar, You can develop UI interface with Web tech."
  s.homepage     = "https://www.github.com/douban/rexxar-ios"
  s.author       = { "iOS Dev" => "ios-dev@douban.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/douban/rexxar-ios.git",
                     :tag => "#{s.version}" }
  s.requires_arc = true
  s.source_files = "Rexxar/**/*.{h,m}"
  s.public_header_files = 'Rexxar/Rexxar.h'

  s.framework    = "UIKit"

  s.subspec 'Core' do |core|
    core.source_files  = 'Rexxar/Core/**/*.{h,m}', 'Rexxar/ContainerAPI/**/*.{h,m}', 'Rexxar/Decorator/**/*.{h,m}'
    core.frameworks    = 'UIKit'
    core.requires_arc  = true
  end

  s.subspec 'Widget' do |widget|
    widget.source_files  = 'Rexxar/Widget/**/*.{h,m}'
    widget.requires_arc  = true
    widget.xcconfig = {"GCC_PREPROCESSOR_DEFINITIONS" => 'DSK_WIDGET=1'}
    widget.dependency 'Rexxar/Core'
  end

  s.default_subspec = 'Widget'

end
