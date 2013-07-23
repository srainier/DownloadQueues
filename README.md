DownloadQueues
==============

DownloadQueues is a simple library for managing multiple groups of downloads.

Does your app have different assets with different download requirements? Maybe
some are small and need to be downloaded as quickly as possible while others
are large and should be downloaded one-at-a-time. DownloadQueues provides a way
to manage these differing groups of downloads independently.

## A Concrete Example with Sample Code

A barebones podcast client will need to download two distinct asset types: RSS
(xml) files and mp3 files. A user could reasonably have 20+ podcast
subscriptions and will want them all to refresh as quickly as possible. RSS
files are relatively small (10s of KBs) and can be downloaded simultaneously.
Mp3 files, on the other hand, are much larger (10s of MBs) and should not be
downloaded simultaneously. Though the number of concurrent Mp3 downloads should
be smaller, this restriction should not prevent RSS files from being
downloaded. Solution: Two download queues - one for RSS files, one for Mp3
files:

```objective-c
#import "DownloadQueues.h"

DownloadQueues *queues = [[DownloadQueues alloc] init];
[queues createQueueWithName:@"rss-files" maxConcurrentDownloads:10];
[queues createQueueWithName:@"mp3-files" maxConcurrentDownloads:1];

NSArray *rssUrls;
for (NSURL *url in rssUrls) {
  [queues downloadUrl:url inQueue:@"rss-files" toData:^(NSError *error, NSData
  *fileData) {
    // Parse the RSS, handle appropriately.
  }];
}

NSArray *mp3Urls;
for (NSURL *url in mp3Urls) {
  [queues downloadUrl:url inQueue:@"mp3-files" toFile:^(NSError *error, NSURL *fileUrl) {
    // Store the downloaded file to a permanent location.
  }];
}
```

## How To Get Started

You'll need to add the following DownloadQueues files to your project:

* DownloadQueues.h/DownloadQueues.m
* DownloadItem.h/DownloadItem.m
* DownloadQueuesDelegate.h
* NSFileManager+DQTempFile.h/NSFileManager+DQTempFile.m

DownloadQueues uses [AFNetworking](https://github.com/AFNetworking/AFNetworking) internally.
If you already use AFNetworking (>= 1.3) in your app you're good! If not, now's a great time to start.

## Requirements

DownloadQueues uses ARC and is only supported for iOS 5 and later.

## Credits and Contact

DownloadQueues was created by [Shane Arney](http://github.com/srainier) to scratch a side-project itch.
You can find him on twitter at [@srainier](https://twitter.com/srainier)
