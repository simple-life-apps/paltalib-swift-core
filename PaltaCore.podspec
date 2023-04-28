Pod::Spec.new do |spec|
  spec.name                  = 'PaltaCore'
  spec.version               = '3.2.0'
  spec.license               = 'MIT'
  spec.summary               = 'PaltaLib iOS SDK - Core part'
  spec.homepage              = 'https://github.com/Palta-Data-Platform/paltalib-swift-core'
  spec.author                = { "Palta" => "dev@palta.com" }
  spec.source                = { :git => 'https://github.com/Palta-Data-Platform/paltalib-swift-core.git', :tag => "#{spec.version}" }
  spec.requires_arc          = true
  spec.ios.deployment_target = '11.0'
  spec.swift_versions        = '5.3'
  spec.source_files = 'Sources/**/*.swift'
end

