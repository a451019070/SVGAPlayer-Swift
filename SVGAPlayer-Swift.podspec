Pod::Spec.new do |s|
  s.name         = 'SVGAPlayer-Swift'
  s.version      = '1.0.0'
  s.summary      = 'SVGA player written in Swift'
  s.homepage     = 'https://github.com/a451019070/SVGAPlayer-Swift'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'ZX' => 'your@email.com' }
  s.source       = { :git => 'https://github.com/a451019070/SVGAPlayer-Swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '16.0'
  s.swift_version = '5.9'
  s.source_files = 'Source/**/*.swift'
  s.dependency 'SwiftProtobuf', '~> 1.39'
end
