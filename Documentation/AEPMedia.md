[TOC]

# Getting Started
This section walks through how to get up and running with the AEP Swift Media SDK with only a few lines of code.

## Set up a Mobile Property
Set up a mobile property as outlined in the Adobe Experience Platform [docs](https://aep-sdks.gitbook.io/docs/getting-started/create-a-mobile-property)

## Get the Swift Mobile Media

Now that a Mobile Property is created, head over to the [install instructions](https://github.com/adobe/aepsdk-media-ios#installation) to install the SDK.

## Initial SDK Setup

**Swift**

1. Import each of the core extensions in the `AppDelegate` file:

```swift
import AEPCore
import AEPMedia
import AEPAnalytics
import AEPIdentity
```
2. Register the core extensions and configure the SDK with the assigned application identifier.
To do this, add the following code to the Application Delegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

 // Enable debug logging
 MobileCore.setLogLevel(level: .trace)

 MobileCore.registerExtensions([Media.self, Identity.self, Analytics.self], {
 // Use the App id assigned to this application via Adobe Launch
 MobileCore.configureWith(appId: "appId") 
 })  
 return true
}
```
**Objective C**

1. Import each of the core extensions in the `AppDelegate` file:

```objective-c
@import AEPCore;
@import AEPMedia;
@import AEPAnalytics;
@import AEPIdentity;
```
2. Register the core extensions and configure the SDK with the assigned application identifier.
    To do this, add the following code to the Application Delegate's 
    `application didFinishLaunchingWithOptions:` method:

```objective-c
(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions

  // Enable debug logging
  [AEPMobileCore setLogLevel: AEPLogLevelTrace];
    
  [AEPMobileCore registerExtensions:@[AEPMobileIdentity.class, AEPMobileLifecycle.class, AEPMobileAnalytics.class, AEPMobileMedia.class] completion:^{
  // Use the App id assigned to this application via Adobe Launch
  [AEPMobileCore configureWithAppId:@"appId"];
   }];
   return YES;
}
```




# Media API reference
This section details all the APIs provided by Media Analytics, along with sample code snippets on how to properly use the APIs.

## createTracker
Creates a media tracker instance that tracks the playback session. The tracker created should be used to track the streaming content, and it sends periodic pings to the media analytics backend.

{% hint style="info" %}
If called MobileCore.resetIdentities() in the implementation, existing tracker will stop sending pings. A new tracker will need to be created for generating a new media session.
{% endhint %}

**Syntax**

```swift
static func createTracker()
```

**Example**

**Swift**

```swift
let _tracker = Media.createTracker()  // Use the instance for tracking media.
```

**Objective C**

```objectivec
id<AEPMediaTracker> _tracker; 
_tracker = [AEPMobileMedia createTracker];  // Use the instance for tracking media.
```



## createTrackerWithConfig

Creates a media tracker instance based on the configuration to track the playback session.

| Key                        | Description                                                  | Value   | Required |
| :------------------------- | :----------------------------------------------------------- | :------ | :------: |
| `config.channel`           | Channel name for media. Set this to overwrite the channel name configured from launch for media tracked with this tracker instance. | String  |    No    |
| `config.downloadedcontent` | Creates a tracker instance to track downloaded media. Instead of sending periodic pings, the tracker only sends one ping for the entire content. | Boolean |    No    |

**Syntax**

```swift
static func createTrackerWith(config: [String: Any]?)
```

**Examples**

**Swift**

```swift
var config: [String: Any] = [:]
config[MediaConstants.TrackerConfig.CHANNEL] = "custom-channel" // Overrides channel configured from launch
config[MediaConstants.TrackerConfig.DOWNLOADED_CONTENT] = true    // Creates downloaded content tracker

let _tracker = Media.createTrackerWith(config: config)
```

**Objective-C**

```objectivec
id<AEPMediaTracker> _tracker; 
NSMutableDictionary* config = [NSMutableDictionary dictionary];

config[AEPMediaTrackerConfig.CHANNEL] = @"custom-channel"; // Overrides channel configured from launch
config[AEPMediaTrackerConfig.DOWNLOADED_CONTENT] = [NSNumber numberWithBool:true]; // Creates downloaded content tracker

_tracker = [AEPMobileMedia createTrackerWithConfig:config];
```



## createMediaObject

Creates an instance of the Media object.

| Variable Name | Description                            | Required |
| :------------ | :------------------------------------- | :------: |
| `name`        | Media name                             |   Yes    |
| `id`          | Media unique identifier                |   Yes    |
| `length`      | Media length                           |   Yes    |
| `streamType`  | [Stream type](AEPMedia.md#stream-type) |   Yes    |
| `mediaType`   | [Media type](AEPMedia.md#media-type)   |   Yes    |



**Syntax**

```swift
static func createMediaObjectWith(name: String, id: String, length: Double, streamType: String, mediaType: MediaType) -> [String: Any]?
```

**Examples**

**Swift**

```swift
let mediaObject = Media.createMediaObjectWith(name: "video-name", id: "videoId", length: 60, streamType: MediaConstants.StreamType.VOD, mediaType: MediaType.Video)
```

**Objective-C**

```objectivec
NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:@"video-name" id:@"video-id" length:60 streamType:AEPMediaStreamType.VOD mediaType:AEPMediaTypeVideo];
```



## createAdBreakObject

Creates an instance of the AdBreak object.

| Variable Name | Description | Required |
| :--- | :--- | :---: |
| `name` | Ad break name such as pre-roll, mid-roll, and post-roll. | Yes |
| `position` | The number position of the ad break within the content, starting with 1. | Yes |
| `startTime` | Playhead value at the start of the ad break.                 | Yes |

**Syntax**

```swift
static func createAdBreakObjectWith(name: String, position: Int, startTime: Double) -> [String: Any]?
```

**Examples**

**Swift**

```swift
let adBreakObject = Media.createAdBreakObjectWith(name: "adbreak-name", position: 1, startTime: 0)
```

**Objective-C**

```objectivec
NSDictionary *adBreakObject = [AEPMobileMedia createAdBreakObjectWith:@"adbreak-name" position:1 startTime:0];
```



## createAdObject

Creates an instance of the Ad object.

| Variable Name | Description                                                  | Required |
| :------------ | :----------------------------------------------------------- | :------: |
| `name`        | Friendly name of the ad.                                     |   Yes    |
| `id`          | Unique identifier for the ad.                                |   Yes    |
| `position`    | The number position of the ad within the ad break, starting with 1. |   Yes    |
| `length`      | Ad length                                                    |   Yes    |

**Syntax**

```swift
static func createAdObjectWith(name: String, id: String, position: Int, length: Double) -> [String: Any]?
```

**Examples**

**Swift**

```swift
let adObject = Media.createObjectWith(name: "ad-name", id: "ad-id", position: 0, length: 30)
```

**Objective-C**

```objectivec
NSDictionary *adObject = [AEPMobileMedia createAdObjectWith:@"ad-name" id:@"ad-id" position:0 length:30];
```



## createChapterObject

Creates an instance of the Chapter object.

| Variable Name | Description                                                  | Required |
| :------------ | :----------------------------------------------------------- | :------: |
| `name`        | Chapter name                                                 |   Yes    |
| `position`    | The number position of the chapter within the content, starting with 1. |   Yes    |
| `length`      | Chapter length                                               |   Yes    |
| `startTime`   | Playhead value at the start of the chapter                   |   Yes    |

**Syntax**

```swift
static func createChapterObjectWith(name: String, position: Int, length: Double, startTime: Double) -> [String: Any]?
```

**Examples**

**Swift**

```swift
let chapterObject = Media.createChapterObjectWith(name: "chapter_name", position: 1, length: 60, startTime: 0)
```

**Objective-C**

```objectivec
NSDictionary *chapterObject = [AEPMobileMedia createChapterObjectWith:@"chapter_name" position:1 length:60 startTime:0];
```



## createQoEObject

Creates an instance of the QoE object.

| Variable Name   | Description              | Required |
| :-------------- | :----------------------- | :------: |
| `bitrate`       | Current bitrate          |   Yes    |
| `startupTime`   | Startup time             |   Yes    |
| `fps`           | FPS value                |   Yes    |
| `droppedFrames` | Number of dropped frames |   Yes    |

**Syntax**

```swift
static func createQoEObjectWith(bitrate: Double, startupTime: Double, fps: Double, droppedFrames: Double) -> [String: Any]?
```

**Examples**

**Swift**

```swift
let qoeObject = Media.createQoEObjectWith(bitrate: 500000, startupTime: 2, fps: 24, droppedFrames: 10)
```

**Objective-C**

```objectivec
NSDictionary *qoeObject = [AEPMobileMedia createQoEObjectWith:50000 startTime:2 fps:24 droppedFrames:10];
```



## createStateObject

Creates an instance of the Player State object.

| Variable Name | Description                                                  | Required |
| :------------ | :----------------------------------------------------------- | :------: |
| `stateName`   | State name\(Use [Player State constants](AEPMedia.md#player-state-constants) to track standard player states\) |   Yes    |

**Syntax**

```swift
static func createStateObjectWith(stateName: String) -> [String: Any]
```

**Examples**

**Swift**

```swift
let fullScreenState = Media.createStateObjectWith(stateName: "fullscreen")
```

**Objective-C**

```objectivec
NSDictionary* fullScreenState = [AEPMobileMedia createStateObjectWith:AEPMediaPlayerState.FULLSCREEN]
```



# Media Tracker API referene

## trackSessionStart

Tracks the intention to start playback. This should be called first to start a tracking session on the media tracker instance. 

Also refer to [Media Resume](AEPMedia.md#media-resume) when resuming a previously closed session.

| Variable Name | Description                                                  | Required |
| :------------ | :----------------------------------------------------------- | :------: |
| `info`        | Media information created using the [createMediaObject](AEPMedia.md#createmediaobject) method. |   Yes    |
| `metadata`    | Optional media metadata. For standard metadata keys, use [standard video constants](AEPMedia.md.md#standard-video-constants) or [standard audio constants](AEPMedia.md.md#standard-audio-constants). |    No    |

**Syntax**

```swift
public func trackSessionStart(info: [String: Any], metadata: [String: String]? = nil)
```

**Examples**

**Swift**

```swift
let mediaObject = Media.createMediaObjectWith(name: "video-name", id: "videoId", length: 60, streamType: MediaConstants.StreamType.VOD, mediaType: MediaType.Video)

var videoMetadata: [String: String] = [:]
// Sample implementation for using video standard metadata keys
videoMetadata[MediaConstants.VideoMetadataKeys.SHOW] = "Sample show"
videoMetadata[MediaConstants.VideoMetadataKeys.SEASON] = "Sample season"

// Sample implementation for using custom metadata keys
videoMetadata["isUserLoggedIn"] = "false"
videoMetadata["tvStation"] = "Sample TV station"

_tracker.trackSessionStart(info: mediaObject, metadata: videoMetadata)
```

**Objective-C**

```objectivec
NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:@"video-name" id:@"video-id" length:60 streamType:AEPMediaStreamType.VOD mediaType:AEPMediaTypeVideo];
    
NSMutableDictionary *videoMetadata = [[NSMutableDictionary alloc] init];
// Sample implementation for using standard video metadata keys
[videoMetadata setObject:@"Sample show" forKey:AEPVideoMetadataKeys.SHOW];
[videoMetadata setObject:@"Sample Season" forKey:AEPVideoMetadataKeys.SEASON];

// Sample implementation for using custom metadata keys
[videoMetadata setObject:@"false" forKey:@"isUserLoggedIn"];
[videoMetadata setObject:@"Sample TV station" forKey:@"tvStation"];

[_tracker trackSessionStart:mediaObject metadata:videoMetadata];
```



## trackPlay

Tracks the media play, or resume, after a previous pause.

**Syntax**

```swift
func trackPlay()
```

**Examples**

**Swift**

```swift
_tracker.trackPlay()
```

**Objective-C**

```objectivec
[_tracker trackPlay];
```



## trackPause

Tracks the media pause.

**Syntax**

```swift
func trackPause()
```

**Examples**

**Swift**

```swift
_tracker.trackPause();
```

**Objective-C**

```objectivec
[_tracker trackPause];
```



## trackComplete

Tracks media complete. Call this method only when the media has been completely viewed.

**Syntax**

```swift
func trackComplete()
```

**Examples**

**Swift**

```swift
_tracker.trackComplete();
```

**Objective-C**

```objectivec
[_tracker trackComplete];
```



## trackSessionEnd

Tracks the end of a viewing session. Call this method even if the user does not view the media to completion.

**Syntax**

```swift
func trackSessionEnd()
```

**Examples**

**Swift**

```swift
_tracker.trackSessionEnd();
```

**Objective-C**

```objectivec
[_tracker trackSessionEnd];
```



## trackError

Tracks an error in media playback.

| Variable Name | Description       | Required |
| :------------ | :---------------- | :------: |
| `errorId`     | Error Information |   Yes    |

**Syntax**

```swift
func trackError(errorId: String)
```

**Examples**

**Swift**

```swift
_tracker.trackError(errorId: "errorId")
```

**Objective-C**

```objectivec
_tracker trackError:@"errorId"];
```



## trackEvent

Tracks media events.

| Variable Name | Description                                                  |
| :------------ | :----------------------------------------------------------- |
| `event`       | [Media event](AEPMedia.md#media-events)                      |
| `info`        | For an `AdBreakStart` event, the Ad Break information is created by using the [createAdBreakObject](AEPMedia.md#createadbreakobject) method.   For an `AdStart` event, the Ad information is created by using the [createAdObject](AEPMedia.md#createadobject) method.   For `ChapterStart` event, the Chapter information is created by using the [createChapterObject](AEPMedia.md#createchapterobject) method.  For `StateStart` and `StateEnd` event, the State information is created by using the [createStateObject](AEPMedia.md#createstateobject) method. |
| `metadata`    | Optional context data can be provided for `AdStart` and `ChapterStart` events. This is not required for other events. |

**Syntax**

```swift
func trackEvent(event: MediaEvent, info: [String: Any]?, metadata: [String: String]?)
```

**Example**

#### Tracking AdBreaks

**Swift**

```swift
// AdBreakStart
  let adBreakObject = Media.createAdBreakObjectWith(name: "adbreak-name", position: 1, startTime: 0)
  _tracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakObject, metadata: nil)

// AdBreakComplete
  _tracker.trackEvent(event: MediaEvent.AdBreakComplete, info: nil, metadata: nil)
```

**Objective C**

```objectivec
// AdBreakStart
  NSDictionary *adBreakObject = [AEPMobileMedia createAdBreakObjectWith:@"adbreak-name" position:1 startTime:0];
  [_tracker trackEvent:AEPMediaEventAdBreakStart info:adBreakObject metadata:nil];
     
// AdBreakComplete
  [_tracker trackEvent:AEPMediaEventAdBreakComplete info:nil metadata:nil];
```



#### Tracking Ads

**Swift**

```swift
// AdStart
  let adObject = Media.createObjectWith(name: "adbreak-name", id: "ad-id", position: 0, length: 30)

// Standard metadata keys provided by adobe.
  var adMetadata: [String: String] = [:]
  adMetadata[MediaConstants.AdMetadataKeys.ADVERTISER] = "Sample Advertiser"
  adMetadata[MediaConstants.AdMetadataKeys.CAMPAIGN_ID] = "Sample Campaign"

// Custom metadata keys
  adMetadata["affiliate"] = "Sample affiliate"

  _tracker.trackEvent(event: MediaEvent.AdStart, info: adObject, metadata: adMetadata)

// AdComplete
  _tracker.trackEvent(event: MediaEvent.AdComplete, info: nil, metadata: nil)

// AdSkip
   _tracker.trackEvent(event: MediaEvent.AdSkip, info: nil, metadata: nil)
```

**Objective C**

```objectivec
// AdStart
  NSDictionary *adObject = [AEPMobileMedia createAdObjectWith:@"ad-name" id:@"ad-id" position:0 length:30];
  NSMutableDictionary* adMetadata = [[NSMutableDictionary alloc] init];

// Standard metadata keys provided by adobe.
  [adMetadata setObject:@"Sample Advertiser" forKey:AEPAdMetadataKeys.ADVERTISER];
  [adMetadata setObject:@"Sample Campaign" forKey:AEPAdMetadataKeys.CAMPAIGN_ID];
// Custom metadata keys
  [adMetadata setObject:@"Sample affiliate" forKey:@"affiliate"];

  [_tracker trackEvent:AEPMediaEventAdStart info:adObject metadata:adMetadata];

// AdComplete
  [_tracker trackEvent:AEPMediaEventAdComplete info:nil metadata:nil];

// AdSkip
  [_tracker trackEvent:AEPMediaEventAdSkip info:nil metadata:nil];
```

#### Tracking Chapters

**Swift**

```swift
// ChapterStart
  let chapterObject = Media.createChapterObjectWith(name: "chapter_name", position: 1, length: 60, startTime: 0)
  let chapterDictionary = ["segmentType": "Sample segment type"]

  _tracker.trackEvent(event: MediaEvent.ChapterStart, info: chapterObject, metadata: chapterDictionary)

// ChapterComplete
  _tracker.trackEvent(event: MediaEvent.ChapterComplete, info: nil, metadata: nil)

// ChapterSkip
  _tracker.trackEvent(event: MediaEvent.ChapterSkip, info: nil, metadata: nil)
```

**Objective C**

```objectivec
// ChapterStart
  NSDictionary *chapterObject = [AEPMobileMedia createChapterObjectWith:@"chapter_name" position:1 length:60 startTime:0];

  NSMutableDictionary *chapterMetadata = [[NSMutableDictionary alloc] init];
  [chapterMetadata setObject:@"Sample segment type" forKey:@"segmentType"];

  [_tracker trackEvent:AEPMediaEventChapterStart info:chapterObject metadata:chapterMetadata];

// ChapterComplete
  [_tracker trackEvent:AEPMediaEventChapterComplete info:nil metadata:nil];
    
// ChapterSkip
  [_tracker trackEvent:AEPMediaEventChapterSkip info:nil metadata:nil];
```



#### Tracking Playback events

**Swift**

```swift
// BufferStart
   _tracker.trackEvent(event: MediaEvent.BufferStart, info: nil, metadata: nil)

// BufferComplete
   _tracker.trackEvent(event: MediaEvent.BufferComplete, info: nil, metadata: nil)

// SeekStart
   _tracker.trackEvent(event: MediaEvent.SeekStart, info: nil, metadata: nil)

// SeekComplete
   _tracker.trackEvent(event: MediaEvent.SeekComplete, info: nil, metadata: nil)
```

**Objective C**

```objectivec
// BufferStart
  [_tracker trackEvent:AEPMediaEventBufferStart info:nil metadata:nil];

// BufferComplete
  [_tracker trackEvent:AEPMediaEventBufferComplete info:nil metadata:nil];

// SeekStart
  [_tracker trackEvent:AEPMediaEventSeekStart info:nil metadata:nil];

// SeekComplete
  [_tracker trackEvent:AEPMediaEventSeekComplete info:nil metadata:nil];
```



#### Tracking Bitrate change

**Swift**

```swift
// If the new bitrate value is available provide it to the tracker.
  let qoeObject = Media.createQoEObjectWith(bitrate: 500000, startupTime: 2, fps: 24, droppedFrames: 10)
  _tracker.updateQoEObject(qoeObject)

// Bitrate change
  _tracker.trackEvent(event: MediaEvent.BitrateChange, info: nil, metadata: nil)
```

**Objective C**

```objectivec
// If the new bitrate value is available provide it to the tracker.
  NSDictionary *qoeObject = [AEPMobileMedia createQoEObjectWith:50000 startTime:2 fps:24 droppedFrames:10];

// Bitrate change
  [_tracker trackEvent:AEPMediaEventBitrateChange info:nil metadata:nil];
```

#### Tracking Player States

**Swift**

```swift
// StateStart
  let fullScreenState = Media.createStateObjectWith(stateName: MediaConstants.PlayerState.FULLSCREEN)
  _tracker.trackEvent(event: MediaEvent.StateStart, info: fullScreenState, metadata: nil)

// StateEnd
  let fullScreenState = Media.createStateObjectWith(stateName: MediaConstants.PlayerState.FULLSCREEN)
  _tracker.trackEvent(event: MediaEvent.StateEnd, info: fullScreenState, metadata: nil)
```

**Objective C**

```objectivec
// StateStart
  NSDictionary* fullScreenState = [AEPMobileMedia createStateObjectWith:AEPMediaPlayerState.FULLSCREEN];
  [_tracker trackEvent:AEPMediaEventStateStart info:fullScreenState metadata:nil];

// StateEnd
  NSDictionary* fullScreenState = [AEPMobileMedia createStateObjectWith:AEPMediaPlayerState.FULLSCREEN];
  [_tracker trackEvent:AEPMediaEventStateEnd info:fullScreenState metadata:nil];
```



## updateCurrentPlayhead

Provides a media tracker with the current media playhead. For accurate tracking, call this method multiple times when the playhead changes.

| Variable Name | Description                                                  |
| :------------ | :----------------------------------------------------------- |
| `time`        | Current playhead in seconds. For video-on-demand \(VOD\), the value is specified in seconds from the beginning of the media item. For live streaming, returns the playhead position if available or the current UTC time in seconds if not available. |

**Syntax**

```swift
func updateCurrentPlayhead(time: Double)
```

**Examples**

**Swift**

```swift
_tracker.updateCurrentPlayhead(1);
```

**Objective-C**

```objectivec
[_tracker updateCurrentPlayhead:1];
```



## updateQoEObject

Provides the media tracker with the current QoE information. For accurate tracking, call this method multiple times when the media player provides the updated QoE information.

| Variable Name | Description                                                  |
| :------------ | :----------------------------------------------------------- |
| `qoe`         | Current QoE information that was created by using the [createQoEObject](AEPMedia.md#createqoeobject) method. |

**Syntax**

```swift
func updateQoEObject(qoe: [String: Any])
```

**Examples**

**Swift**

```swift
let qoeObject = Media.createQoEObjectWith(bitrate: 500000, startupTime: 2, fps: 24, droppedFrames: 10)
_tracker.updateQoEObject(qoe: qoeObject)
```

**Objective-C**

```objectivec
NSDictionary *qoeObject = [AEPMobileMedia createQoEObjectWith:50000 startTime:2 fps:24 droppedFrames:10]
[_tracker updateQoEObject:qoeObject];
```



# Media Constants

## Media type

Defines the type of a media that is currently tracked.

**Syntax**

```swift
@objc(AEPMediaType)
public enum MediaType: Int, RawRepresentable {
 //Constant defining media type for Video streams
 case Audio
 //Constant defining media type for Audio streams
 case Video
}
```

**Example**

**Swift**

```swift
var mediaObject = Media.createMediaObjectWith(name: "video-name", id: "videoId", length: "60", streamType: MediaConstants.StreamType.VOD, mediaType: MediaType.Video)
```

**Objective C**

```objectivec
NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:@"video-name" id:@"video-id" length:60 streamType:AEPMediaStreamType.VOD mediaType:AEPMediaTypeVideo];
```



## Stream type

Defines the stream type of the content that is currently tracked.

**Syntax**

```swift
public class MediaConstants: NSObject {
  @objc(AEPMediaStreamType)
  public class StreamType: NSObject {
     // Constant defining stream type for VOD streams.
        public static let VOD = "vod"
     // Constant defining stream type for Live streams.
        public static let LIVE = "live"
     // Constant defining stream type for Linear streams.
        public static let LINEAR = "linear"
     // Constant defining stream type for Podcast streams.
        public static let PODCAST = "podcast"
     // Constant defining stream type for Audiobook streams.
        public static let AUDIOBOOK = "audiobook"
     // Constant defining stream type for AOD streams.
        public static let AOD = "aod"
    }
}
```

**Example**

**Swift**

```swift
var mediaObject = Media.createMediaObjectWith(name: "video-name", id: "videoId", length: "60", streamType: MediaConstants.StreamType.VOD, mediaType: MediaType.Video)
```

**Objective C**

```objectivec
NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:@"video-name" id:@"video-id" length:60 streamType:AEPMediaStreamType.VOD mediaType:AEPMediaTypeVideo];
```



## Standard video constants

Defines the standard metadata keys for video streams.

**Syntax**

```swift
public class MediaConstants: NSObject {
  @objc(AEPVideoMetadataKeys)
  public class VideoMetadataKeys: NSObject {
        public static let SHOW = "a.media.show"
        public static let SEASON = "a.media.season"
        public static let EPISODE = "a.media.episode"
        public static let ASSET_ID = "a.media.asset"
        public static let GENRE = "a.media.genre"
        public static let FIRST_AIR_DATE = "a.media.airDate"
        public static let FIRST_DIGITAL_DATE = "a.media.digitalDate"
        public static let RATING = "a.media.rating"
        public static let ORIGINATOR = "a.media.originator"
        public static let NETWORK = "a.media.network"
        public static let SHOW_TYPE = "a.media.type"
        public static let AD_LOAD = "a.media.adLoad"
        public static let MVPD = "a.media.pass.mvpd"
        public static let AUTHORIZED = "a.media.pass.auth"
        public static let DAY_PART = "a.media.dayPart"
        public static let FEED = "a.media.feed"
        public static let STREAM_FORMAT = "a.media.format"
    }
}
```

**Example**

**Swift**

```swift
var mediaObject = Media.createMediaObjectWith(name: "video-name", id: "videoId", length: "60", streamType: MediaConstants.StreamType.VOD, mediaType: MediaType.Video)

var videoMetadata: [String: String] = [:]
// Standard Video Metadata
videoMetadata[MediaConstants.VideoMetadataKeys.SHOW] = "Sample show"
videoMetadata[MediaConstants.VideoMetadataKeys.SEASON] = "Sample season"

_tracker.trackSessionStart(info: mediaObject, metadata: videoMetadata)
```

**Objective C**

```objectivec
NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:@"video-name" id:@"video-id" length:60 streamType:AEPMediaStreamType.VOD mediaType:AEPMediaTypeVideo];
    
NSMutableDictionary *videoMetadata = [[NSMutableDictionary alloc] init];
// Standard Video Metadata
[videoMetadata setObject:@"Sample show" forKey:AEPVideoMetadataKeys.SHOW];
[videoMetadata setObject:@"Sample Season" forKey:AEPVideoMetadataKeys.SEASON];

[_tracker trackSessionStart:mediaObject metadata:videoMetadata];
```



## Standard audio constants

Defines the standard metadata keys for audio streams.

**Syntax**

```swift
public class MediaConstants: NSObject {
  @objc(AEPAudioMetadataKeys)
  public class AudioMetadataKeys: NSObject {
        public static let ARTIST = "a.media.artist"
        public static let ALBUM = "a.media.album"
        public static let LABEL = "a.media.label"
        public static let AUTHOR = "a.media.author"
        public static let STATION = "a.media.station"
        public static let PUBLISHER = "a.media.publisher"
    }
}
```

**Example**

**Swift**

```swift
var audioObject = Media.createMediaObjectWith(name: "audio-name", id: "audioId", length: 30, streamType: MediaConstants.StreamType.AOD, mediaType: MediaType.AUDIO)

var audioMetadata: [String: String] = [:]
// Standard Audio Metadata
audioMetadata[MediaConstants.AudioMetadataKeys.ARTIST] = "Sample artist"
audioMetadata[MediaConstants.AudioMetadataKeys.ALBUM] = "Sample album"

_tracker.trackSessionStart(info: audioObject, metadata: audioMetadata)
```

**Objective C**

```objectivec
NSDictionary *audioObject = [AEPMobileMedia createMediaObjectWith:@"audio-name" id:@"audioid" length:30 streamType:AEPMediaStreamType.AOD mediaType:AEPMediaTypeAudio];
    
NSMutableDictionary *audioMetadata = [[NSMutableDictionary alloc] init];
// Standard Audio Metadata
[audioMetadata setObject:@"Sample artist" forKey:AEPAudioMetadataKeys.ARTIST];
[audioMetadata setObject:@"Sample album" forKey:AEPAudioMetadataKeys.ALBUM];

[_tracker trackSessionStart:audioObject metadata:audioMetadata];
```



## Standard ad constants

Defines the standard metadata keys for ads.

**Syntax**

```swift
public class MediaConstants: NSObject {
  @objc(AEPAdMetadataKeys)
  public class AdMetadataKeys: NSObject {
        public static let ADVERTISER = "a.media.ad.advertiser"
        public static let CAMPAIGN_ID = "a.media.ad.campaign"
        public static let CREATIVE_ID = "a.media.ad.creative"
        public static let PLACEMENT_ID = "a.media.ad.placement"
        public static let SITE_ID = "a.media.ad.site"
        public static let CREATIVE_URL = "a.media.ad.creativeURL"
    }
}
```

**Example**

**Swift**

```swift
let adObject = Media.createObjectWith(name: "adbreak-name", id: "ad-id", position: 0, length: 30)
var adMetadata: [String: String] = [:]
// Standard Ad Metadata
adMetadata[MediaConstants.AdMetadataKeys.ADVERTISER] = "Sample Advertiser"
adMetadata[MediaConstants.AdMetadataKeys.CAMPAIGN_ID] = "Sample Campaign"

_tracker.trackEvent(event: MediaEvent.AdStart, info: adObject, metadata: adMetadata)
```

**Objective C**

```objectivec
NSDictionary *adObject = [AEPMobileMedia createAdObjectWith:@"ad-name" id:@"ad-id" position:0 length:30];
                   
NSMutableDictionary *adMetadata = [[NSMutableDictionary alloc] init];
// Standard Ad Metadata
[adMetadata setObject:@"Sample Advertiser" forKey:AEPAdMetadataKeys.ADVERTISER];
[adMetadata setObject:@"Sample Campaign" forKey:AEPAdMetadataKeys.CAMPAIGN_ID];

[_tracker trackEvent:AEPMediaEventAdStart info:adObject metadata:adMetadata];
}
```



## Player state constants

Defines some common Player State constants.

**Syntax**

```swift
public class MediaConstants: NSObject {
  @objc(AEPMediaPlayerState)
  public class PlayerState: NSObject {
        public static let FULLSCREEN = "fullscreen"
        public static let PICTURE_IN_PICTURE = "pictureInPicture"
        public static let CLOSED_CAPTION = "closedCaptioning"
        public static let IN_FOCUS = "inFocus"
        public static let MUTE = "mute"
    }
}
```

**Example**

**Swift**

```swift
let inFocusState = Media.createStateObjectWith(stateName: MediaConstants.PlayerState.IN_FOCUS)
_tracker.trackEvent(event: MediaEvent.StateStart, info: inFocusState, metadata: nil)
```

**Objective C**

```objectivec
NSDictionary* inFocusState = [AEPMobileMedia createStateObjectWith:AEPMediaPlayerState.IN_FOCUS];
[_tracker trackEvent:AEPMediaEventStateStart info:muteState metadata:nil];
```



## Media events

Defines the type of a tracking event.

**Syntax**

```swift
@objc(AEPMediaEvent)
public enum MediaEvent: Int, RawRepresentable {
  // event type for AdBreak start
    case AdBreakStart
 // event type for AdBreak Complete
    case AdBreakComplete
 // event type for Ad Start
    case AdStart
 // event type for Ad Complete
    case AdComplete
 // event type for Ad Skip
    case AdSkip
 // event type for Chapter Start
    case ChapterStart
 // event type for Chapter Complete
    case ChapterComplete
 // event type for Chapter Skip
    case ChapterSkip
 // event type for Seek Start
    case SeekStart
 // event type for Seek Complete
    case SeekComplete
 // event type for Buffer Start
    case BufferStart
 // event type for Buffer Complete
    case BufferComplete
 // event type for change in Bitrate
    case BitrateChange
 // event type for Player State Start
    case StateStart
 // event type for Player State End
    case StateEnd
}
```

**Example**

**Swift**

```swift
_tracker.trackEvent(event: MediaEvent.BitrateChange, info: nil, metadata: nil)
```

**Objective C**

```objectivec
[_tracker trackEvent:AEPMediaEventBitrateChange info:nil metadata:nil];
```



## Media resume

Constant to denote that the current tracking session is resuming a previously closed session. This information **must** be provided when starting a tracking session.

**Syntax**

```swift
public class MediaConstants: NSObject {
 @objc(AEPMediaObjectKey)
 public class MediaObjectKey: NSObject {
        public static let RESUMED = "media.resumed"
    }
}
```

**Example**

**Swift**

```swift
var mediaObject = Media.createMediaObjectWith(name: "video-name", id: "videoId", length: "60", streamType: MediaConstants.StreamType.VOD, mediaType: MediaType.Video)
mediaObject[MediaConstants.MediaObjectKey.RESUMED] = true

_tracker.trackSessionStart(info: mediaObject, metadata: nil)
```

**Objective C**

```objectivec
NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:@"video-name" id:@"video-id" length:60 streamType:AEPMediaStreamType.VOD mediaType:AEPMediaTypeVideo];

// Attach media resumed information.    
NSMutableDictionary *obj  = [mediaObject mutableCopy];
[obj setObject:@YES forKey:AEPMediaObjectKey.RESUMED];

[_tracker trackSessionStart:obj metadata:nil];
```



# Related Project

## AEP SDK Compatibility for iOS

| Project                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [AEP SDK Compatibility for iOS](https://github.com/adobe/aepsdk-compatibility-ios) | Contains code that bridges `ACPMedia` implementations into the AEP SDK runtime. |

