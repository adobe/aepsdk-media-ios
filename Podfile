platform :ios, '12.0'
use_frameworks!

workspace 'AEPMedia'
project 'AEPMedia.xcodeproj'

pod 'SwiftLint', '0.52.0'

def core_pods
  pod 'AEPServices'
  pod 'AEPCore'
  pod 'AEPIdentity'
  pod 'AEPRulesEngine'
end

def test_pods
  core_pods
  pod 'AEPLifecycle'
  pod 'AEPAnalytics', :git => 'https://github.com/adobe/aepsdk-analytics-ios.git', :branch => 'staging'
end

target 'AEPMedia' do
  core_pods
end

target 'UnitTests' do
  core_pods
end

target 'FunctionalTests' do
  core_pods
end

target 'TestAppiOS' do
  test_pods
  pod 'AEPAssurance', :git => 'https://github.com/adobe/aepsdk-assurance-ios.git', :branch => 'staging'
end

target 'TestApptvOS' do
  test_pods
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '12.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end
