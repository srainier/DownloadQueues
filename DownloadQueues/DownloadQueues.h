//
// DownloadQueues.h
//
// Copyright (c) 2012 Shane Arney (srainier@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "DownloadQueuesDelegate.h"
@class DownloadQueues;
@class DownloadItem;
@class AFURLConnectionOperation;

// TODO: Delegate should be in its own file.
// TODO: Shouldn't there be NSNotifications for every delegate callback?

// Restart here:
// 4. add ability to query state of download operation.
// 5. back to item info controller to actually download the files.


@interface DownloadQueues : NSObject

@property (nonatomic, retain) id<DownloadQueuesDelegate> delegate;

- (BOOL) createQueueWithName:(NSString*)queueName;
- (BOOL) createQueueWithName:(NSString*)queueName maxConcurrentDownloads:(NSInteger)maxConcurrentDownloads;

- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName toFile:(void(^)(NSError*, NSURL*))completeCallback;
- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName toData:(void(^)(NSError*, NSData*))completeCallback;

- (NSArray*) allQueueNames;
- (NSArray*) itemsInQueue:(NSString*)queueName;

- (BOOL) isItemPaused:(DownloadItem*)item;
- (BOOL) pauseItem:(DownloadItem*)item;
- (BOOL) resumeItem:(DownloadItem*)item;

- (BOOL) cancelItem:(DownloadItem*)item;

@end
