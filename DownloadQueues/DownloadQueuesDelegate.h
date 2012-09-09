//
// DownloadQueuesDelegate.h
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
@class DownloadQueues;
@class DownloadItem;

// NSNotification names.
extern NSString* const DQDownloadProgressEvent;
extern NSString* const DQDownloadDidStartEvent;
extern NSString* const DQDownloadDidPauseEvent;
extern NSString* const DQDownloadDidResumeEvent;
extern NSString* const DQDownloadDidCancelEvent;
extern NSString* const DQDownloadDidCompleteEvent;
extern NSString* const DQDownloadDidFailEvent;

// NSNotification keys.
extern NSString* const DQQueue;
extern NSString* const DQItem;
extern NSString* const DQOrderInQueue;
extern NSString* const DQTotalBytesRead;
extern NSString* const DQTotalBytesExpectedToRead;
extern NSString* const DQPercentComplete;
extern NSString* const DQError;

@protocol DownloadQueuesDelegate <NSObject>

@optional

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue
     totalBytesRead:(long long)totalBytesRead
totalBytesExpectedToRead:(long long)totalBytesExpectedToRead
    percentComplete:(float)percentComplete;

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
       didStartItem:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue;

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
       didPauseItem:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue;

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
      didResumeItem:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue;

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
      didCancelItem:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue;

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue
didCompleteWithData:(NSData*)data;

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue
didCompleteWithFile:(NSURL*)file;

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem*)item
       orderInQueue:(NSUInteger)orderInQueue
   didFailWithError:(NSError*)error;

@end

