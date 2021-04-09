export EXTENSION_NAME = AEPMedia
PROJECT_NAME = $(EXTENSION_NAME)
TARGET_NAME_XCFRAMEWORK = $(EXTENSION_NAME).xcframework
SCHEME_NAME_XCFRAMEWORK = AEPMedia

SIMULATOR_ARCHIVE_PATH = ./build/ios_simulator.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_PATH = ./build/ios.xcarchive/Products/Library/Frameworks/

setup:
	(cd build && pod install)

setup-tools: install-swiftlint install-githook

pod-repo-update:
	(cd build && pod repo update)

# pod repo update may fail if there is no repo (issue fixed in v1.8.4). Use pod install --repo-update instead
pod-install:
	(cd build && pod install --repo-update)

pod-update: pod-repo-update
	(cd build && pod update)

bundle-exec-pod-install:
	(cd build && bundle exec pod install)

open:
	open build/$(PROJECT_NAME).xcworkspace

test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace build/$(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES

install-swiftlint:
	HOMEBREW_NO_AUTO_UPDATE=1 brew install swiftlint && brew cleanup swiftlint

archive:
	xcodebuild archive -workspace build/$(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace build/$(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework -framework $(IOS_ARCHIVE_PATH)$(PROJECT_NAME).framework -output ./build/$(TARGET_NAME_XCFRAMEWORK)

clean:
	rm -rf ./build

lint:
	swiftlint lint

lint-autocorrect:
	swiftlint autocorrect

checkFormat:
	swiftformat . --lint --swiftversion 5.2

format:
	swiftformat . --swiftversion 5.2
