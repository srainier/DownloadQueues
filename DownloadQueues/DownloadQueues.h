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

/**
 `DownloadQueues` provides the ability to manage groups of concurrent downloads.
 */
@interface DownloadQueues : NSObject

/**
 The delegate that will receive all download events.
 */
@property (nonatomic, retain) id<DownloadQueuesDelegate> delegate;

/**
 Creates a new queue that can be used to download items.

 This is the same as calling `createQueueWithName:maxConcurrentDownloads:` with `NSOperationQueueDefaultMaxConcurrentOperationCount` passed to `maxConcurrentDownloads`.
 
 @param queueName The queue's string identifier.
 @return `Yes` if the queue is created, `NO` if a queue already exists for the input name.
 */
- (BOOL) createQueueWithName:(NSString*)queueName;

/**
 Creates a new queue that can be used to download items.
 
 This method allows the caller to restrict the number of concurrent downloads on the queue.
 
 @param queueName The queue's string identifier.
 @param maxConcurrentDownloads The maximum number of concurrent downloads for this queue.
 @return `Yes` if the queue is created, `NO` if a queue already exists for the input name.
 */
- (BOOL) createQueueWithName:(NSString*)queueName maxConcurrentDownloads:(NSInteger)maxConcurrentDownloads;

/**
 Request an asset at a specified url be downloaded to file.
 
 This method will download the content at `url` to a temporary file location. Once complete the caller
 can move or copy the downloaded file to a permanent location for their own use. The caller is not required
 to delete the temporary file but should do so if many temporary files are going to be created. If the caller
 wants to keep the file beyond the scope of the callback then the file should be moved to a caller-controlled
 location. The temporary file is not guaranteed to stay in its temporary location after the callback is done
 executing.
 
 @param url The url for the asset to be downloaded.
 @param queueName The name of the queue to use.
 @param completeCallback A block that will be called when the download completes. If the download succeeds the `NSError *` will be nil and the `NSURL *` will be a path to the temporary file. If the download fails the `NSError *` will be set with information about the error.
 */
- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName toFile:(void(^)(NSError*, NSURL*))completeCallback;

/**
 Request an asset at a specified url be downloaded to file.
 
 This method will download the content at `url` to a temporary file location. Once complete the caller
 can move or copy the downloaded file to a permanent location for their own use. The caller is not required
 to delete the temporary file but should do so if many temporary files are going to be created. If the caller
 wants to keep the file beyond the scope of the callback then the file should be moved to a caller-controlled
 location. The temporary file is not guaranteed to stay in its temporary location after the callback is done
 executing.
 
 @param url The url for the asset to be downloaded.
 @param userInfo Metadata the caller can attach to the download. This data will be attached to the corresponding `DownloadItem *` for this download.
 @param queueName The name of the queue to use.
 @param completeCallback A block that will be called when the download completes. If the download succeeds the `NSError *` will be nil and the `NSURL *` will be a path to the temporary file. If the download fails the `NSError *` will be set with information about the error.
 */
- (BOOL) downloadUrl:(NSURL*)url userInfo:(id)userInfo inQueue:(NSString*)queueName toFile:(void(^)(NSError*, NSURL*))completeCallback;

/**
 Request an asset at a specified url be downloaded to memory.
 
 This method will download the content at `url` to a `NSData` object.
 
 @param url The url for the asset to be downloaded.
 @param queueName The name of the queue to use.
 @param completeCallback A block that will be called when the download completes. If the download succeeds the `NSError *` will be nil and the `NSData *` will contain the downloaded data. If the download fails the `NSError *` will be set with information about the error.
 */
- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName toData:(void(^)(NSError*, NSData*))completeCallback;

/**
 Request an asset at a specified url be downloaded to memory.
 
 This method will download the content at `url` to a `NSData` object.
 
 @param url The url for the asset to be downloaded.
 @param userInfo Metadata the caller can attach to the download. This data will be attached to the corresponding `DownloadItem *` for this download.
 @param queueName The name of the queue to use.
 @param completeCallback A block that will be called when the download completes. If the download succeeds the `NSError *` will be nil and the `NSData *` will contain the downloaded data. If the download fails the `NSError *` will be set with information about the error.
 */
- (BOOL) downloadUrl:(NSURL*)url userInfo:(id)userInfo inQueue:(NSString*)queueName toData:(void(^)(NSError*, NSData*))completeCallback;

/**
 Retrieve a list of names of all queues that have been created.
 
 @return Array of `NSString *` queue names.
 */
- (NSArray*) allQueueNames;

/**
 Retrieve a list of in-progress downloads in a specific queue.
 
 All downloads that are downloading, paused, or waiting will be returned.
 
 @return Array of `DownloadItem *` objects representing downloading, pause, and waiting downloads.
 */
- (NSArray*) itemsInQueue:(NSString*)queueName;

/**
 Check if a download is paused or in-progress.
 
 An item will be 'paused' if pauseItem: was called for the download's `DownloadItem` and YES was returned.
 
 @param item The `DownloadItem *` representing the download.
 @return `YES` if the download is paused, `NO` otherwise.
 */
- (BOOL) isItemPaused:(DownloadItem*)item;

/**
 Pause a download.
 
 A paused download can be resumed with `resumeDownload:`.
 
 @param item The `DownloadItem *` representing the download.
 @return `YES` if the download was successfully paused, `NO` otherwise.
 */
- (BOOL) pauseItem:(DownloadItem*)item;

/**
 Resume a paused download.
 
 @param item The `DownloadItem *` representing the paused download.
 @return `YES` if the download had been paused and was successfully resumed, `NO` otherwise.
 */
- (BOOL) resumeItem:(DownloadItem*)item;

/**
 Cancel a download.
 
 A canceled download cannot be resumed. Once canceled the record of the download is deleted from the queue.
 
 @param item The `DownloadItem *` to cancel.
 @return `YES` if the download was successfully canceled, `NO` otherwise.
 */
- (BOOL) cancelItem:(DownloadItem*)item;

@end
