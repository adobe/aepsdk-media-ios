# Adobe Experience Platform Media SDK

[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-media-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange)](https://cocoapods.org/pods/AEPMedia) 
[![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-media-ios?label=SPM&logo=apple&logoColor=white&color=orange)](https://github.com/adobe/aepsdk-media-ios/releases) 
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-media-ios/main.svg?logo=circleci&label=Build)](https://circleci.com/gh/adobe/workflows/aepsdk-media-ios) 
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-media-ios/main.svg?logo=codecov&label=Coverage)](https://codecov.io/gh/adobe/aepsdk-media-ios/branch/main)

## About this project

AEPMedia represents the Adobe Experience Platform SDK's Media Analytics extension that provides clients with robust measurement for audio, video and advertisements.

## Requirements
- Xcode 15.0
- Swift 5.1

## Installation
These are currently the supported installation options:

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)
```ruby
# Podfile
use_frameworks!

# For app development, include all the following pods
target 'YOUR_TARGET_NAME' do
    pod 'AEPMedia'
    pod 'AEPAnalytics'
    pod 'AEPCore'
    pod 'AEPIdentity'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPMedia Package to your application, from the Xcode menu select:

`File > Add Packages...`

> **Note** 
>  The menu options may vary depending on the version of Xcode being used.

Enter the URL for the AEPMedia package repository: `https://github.com/adobe/aepsdk-media-ios.git`.

When prompted, input a specific version or a range of versions for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPMedia directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-media-ios.git", .upToNextMajor(from: "5.0.0"))
]
```

### Project Reference

Include `AEPMedia.xcodeproj` in the targeted Xcode project and link all necessary libraries to your app target.

### Binaries

Run `make archive` from the root directory to generate `.xcframeworks` for each module under the `build` folder. Drag and drop all `.xcframeworks` to your app target in Xcode.

## Documentation

Additional documentation for usage and SDK architecture can be found under the [Documentation](Documentation) directory.

## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
