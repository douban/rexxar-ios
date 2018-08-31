#
# Be sure to run `pod lib lint Rexxar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name         = 'Rexxar'
  s.version      = "0.3.0"
  s.license      = { :type => 'MIT', :text => 'LICENSE' }

  s.summary      = "Rexxar Hybrid Framework"
  s.description  = "Rexxar is Douban Hybrid Framework. By Rexxar, You can develop UI interface with Web tech."
  s.homepage     = "https://www.github.com/douban/rexxar-ios"
  s.author       = { "iOS Dev" => "ios-dev@douban.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/douban/rexxar-ios.git",
                     :tag => "#{s.version}" }
  s.requires_arc = true
  s.framework    = "UIKit"

  s.ios.deployment_target = '8.0'

  s.source_files = 'Rexxar/Classes/**/*'
  s.dependency 'MTURLProtocol', '0.1.2'
end
