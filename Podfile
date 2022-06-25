platform :ios, '10.0'
use_frameworks!

workspace 'AEPMedia'
project 'AEPMedia.xcodeproj'

pod 'SwiftLint', '0.44.0'

def core_pods
  pod 'AEPServices'
  pod 'AEPCore'
  pod 'AEPIdentity'
  pod 'AEPRulesEngine'
end

def test_pods
  core_pods
  pod 'AEPLifecycle'
  pod 'AEPAnalytics'
end

target 'AEPMedia' do
  core_pods
end

target 'AEPMediaUnitTests' do
  core_pods
end

target 'AEPMediaFunctionalTests' do
  core_pods
end

target 'MediaSampleApp' do
  test_pods
  pod 'AEPAssurance', '~> 3.0'
end

target 'MediaSampleApp (tvOS)' do
  test_pods
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '10.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end
