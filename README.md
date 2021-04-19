# Adobe Experience Platform Media SDK

[![Cocoapods](https://img.shields.io/cocoapods/v/AEPMedia.svg?color=orange&label=AEPMedia&logo=apple&logoColor=white)](https://cocoapods.org/pods/AEPMedia)

[![SPM](https://img.shields.io/badge/SPM-Supported-orange.svg?logo=apple&logoColor=white)](https://swift.org/package-manager/)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-media-ios/main.svg?logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-media-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-media-ios/main.svg?logo=codecov)](https://codecov.io/gh/adobe/aepsdk-media-ios/branch/main)

## About this project

AEPMedia represents the Adobe Experience Platform SDK's Media Analytics extension that provides clients with robust measurement for audio, video and advertisements.

## Requirements
- Xcode 11.x
- Swift 5.x

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

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPMedia package repository: `https://github.com/adobe/aepsdk-media-ios.git`.

When prompted, make sure you change the branch to `main`. (Once the repo is public, we will reference specific tags/versions instead of a branch)

There are three options for selecting your dependencies as identified by the *suffix* of the library name:

- "Dynamic" - the library will be linked dynamically
- "Static" - the library will be linked statically
- *(none)* - (default) SPM will determine whether the library will be linked dynamically or statically

Alternatively, if your project has a `Package.swift` file, you can add AEPMedia directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-media-ios.git", .branch("main"))
]
```

### Project Reference

Include `AEPMedia.xcodeproj` in the targeted Xcode project and link all necessary libraries to your app target.

### Binaries

Run `make archive` from the root directory to generate `.xcframeworks` for each module under the `build` folder. Drag and drop all `.xcframeworks` to your app target in Xcode.

## Documentation

Additional documentation for usage and SDK architecture can be found under the [Documentation](Documentation/README.md) directory.

## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.