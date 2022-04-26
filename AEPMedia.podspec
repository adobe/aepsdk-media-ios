Pod::Spec.new do |s|
  s.name             = "AEPMedia"
  s.version          = "3.0.1.1"
  s.summary          = "Media library for Adobe Experience Platform SDK. Written and maintained by Adobe."
  s.description      = <<-DESC
The Media library provides APIs that allow use of the Media Analytics product in the Adobe Experience Platform SDK.
                        DESC
  s.homepage         = "https://github.com/adobe/aepsdk-media-ios"
  s.license          = 'Apache V2'
  s.author       = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-media-ios", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'

  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.dependency 'AEPCore'

  s.source_files          = 'AEPMedia/Sources/**/*.swift'


end
