//
// DownloadQueues.m
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

#import "DownloadQueues.h"
#import "AFHTTPRequestOperation.h"
#import "NSFileManager+TempFile.h"
#import "DownloadItem.h"

// Definition of NSNotification constants for DownlaodQueuesDelegate
NSString* const DQDownloadProgressEvent = @"com.DownloadQueues.DQDownloadProgressEvent";
NSString* const DQDownloadDidStartEvent = @"com.DownloadQueues.DQDownloadDidStart";
NSString* const DQDownloadDidPauseEvent = @"com.DownloadQueues.DQDownloadDidPause";
NSString* const DQDownloadDidResumeEvent = @"com.DownloadQueues.DQDownloadDidResume";
NSString* const DQDownloadDidCancelEvent = @"com.DownloadQueues.DQDownloadDidCancel";
NSString* const DQDownloadDidCompleteEvent = @"com.DownloadQueues.DQDownloadDidComplete";
NSString* const DQDownloadDidFailEvent = @"com.DownloadQueues.DQDownloadDidFail";

// Definition of NSNotification userInfo keys for DownloadQueuesDelegate
NSString* const DQQueue = @"queue";
NSString* const DQItem = @"item";
NSString* const DQOrderInQueue = @"orderInQueue";
NSString* const DQTotalBytesRead = @"totalBytesRead";
NSString* const DQTotalBytesExpectedToRead = @"totalBytesExpectedToRead";
NSString* const DQPercentComplete = @"percentComplete";
NSString* const DQData = @"data";
NSString* const DQError = @"error";

@interface DownloadQueues () {
  NSMutableArray* queueNames_;
  NSMutableDictionary* queues_;
  NSMutableDictionary* itemsByQueue_;
}

- (NSOperationQueue*) queueWithName:(NSString*)queueName;
- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName outputFile:(NSURL*)outputFile callback:(void(^)(NSError*, id))completeCallback;
- (void) forItem:(DownloadItem*)item perform:(void (^)(NSString* queueName, AFURLConnectionOperation* operation, NSUInteger orderInQueue))perform;

@end

@interface DownloadItem (StreamDelegate) <NSStreamDelegate>
@end

@implementation DownloadQueues

@synthesize delegate = delegate_;

- (id) init {
  self = [super init];
  if (nil != self) {
    queueNames_ = [NSMutableArray array];
    queues_ = [NSMutableDictionary dictionary];
    itemsByQueue_ = [NSMutableDictionary dictionary];
  }
  return self;
}

- (BOOL) createQueueWithName:(NSString*)queueName {
  return [self createQueueWithName:queueName maxConcurrentDownloads:NSOperationQueueDefaultMaxConcurrentOperationCount];
}

- (BOOL) createQueueWithName:(NSString*)queueName maxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
  
  if (nil != [queues_ objectForKey:queueName]) {
    @throw [NSException exceptionWithName:@"CreateQueueFailure"
                                   reason:[NSString stringWithFormat:@"Queue %@ already exists", queueName] userInfo:nil];
  }
  
  // NOTE: it may be advantageous to be able to specify the priority of an operation.  It would make
  // sense for it to be queue-based, but I only see the following on NSOperation:
  // - (void)setThreadPriority:(double)priority.
  // Look into this later if necessary.
  
  NSOperationQueue* queue = [[NSOperationQueue alloc] init];
  [queueNames_ addObject:queueName];
  [queues_ setObject:queue forKey:queueName];
  [itemsByQueue_ setObject:[NSMutableArray array] forKey:queueName];
  [queue setMaxConcurrentOperationCount:maxConcurrentDownloads];
  [queue setSuspended:NO];
  
  return YES;  
}

- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName toFile:(void(^)(NSError*, NSURL*))completeCallback {
  
  // Create a file that the downloaded data can be written to.
  NSURL* tempFile = [[NSFileManager defaultManager] createTemporaryFile];
  
  // Call the helper
  return [self downloadUrl:url inQueue:queueName outputFile:tempFile callback:completeCallback];
}

- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName toData:(void(^)(NSError*, NSData*))completeCallback {

  // Call the helper
  return [self downloadUrl:url inQueue:queueName outputFile:nil callback:completeCallback];
}

- (NSArray*) allQueueNames {
  return [NSArray arrayWithArray:queueNames_];
}

- (NSArray*) itemsInQueue:(NSString*)queueName {
  return [NSArray arrayWithArray:[itemsByQueue_ objectForKey:queueName]];
}

- (BOOL) isItemPaused:(DownloadItem*)item {
  
  __block BOOL isPaused = NO;
  [self forItem:item perform:^(NSString *queueName, AFURLConnectionOperation *operation, NSUInteger orderInQueue) {
    isPaused = operation.isPaused;
  }];  
  return isPaused;
}

- (BOOL) pauseItem:(DownloadItem*)item {
  __block BOOL didPause = NO;
  [self forItem:item perform:^(NSString* queueName, AFURLConnectionOperation* operation, NSUInteger orderInQueue) {
    if (operation.isPaused || operation.isFinished) {
      didPause = NO;
    } else {
      [operation pause];
      
      if ([self.delegate respondsToSelector:@selector(downloader:queue:didPauseItem:orderInQueue:)]) {
        [self.delegate downloader:self queue:queueName didPauseItem:item orderInQueue:orderInQueue];        
      }
      
      [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadDidPauseEvent
                                                          object:self
                                                        userInfo:@{ DQQueue : queueName,
                                                                     DQItem : item,
                                                             DQOrderInQueue : @(orderInQueue) }];
      
      didPause = YES;
    }
  }];
  return didPause;
}

- (BOOL) resumeItem:(DownloadItem*)item {
  __block BOOL didResume = NO;
  [self forItem:item perform:^(NSString* queueName, AFURLConnectionOperation* operation, NSUInteger orderInQueue) {
    if (!operation.isPaused || operation.isFinished) {
      didResume = NO;
    } else {
      [operation resume];

      if ([self.delegate respondsToSelector:@selector(downloader:queue:didResumeItem:orderInQueue:)]) {
        [self.delegate downloader:self queue:queueName didResumeItem:item orderInQueue:orderInQueue];
      }

      [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadDidResumeEvent
                                                          object:self
                                                        userInfo:@{ DQQueue : queueName,
                                                                     DQItem : item,
                                                             DQOrderInQueue : @(orderInQueue) }];
      didResume = YES;
    }
  }];
  return didResume;
}

- (BOOL) cancelItem:(DownloadItem*)item {
  __block BOOL isCancelled = NO;
  [itemsByQueue_ enumerateKeysAndObjectsUsingBlock:^(id queueName, id items, BOOL *stop) {
    NSUInteger index = [items indexOfObject:item];
    if (NSNotFound != index) {
      *stop = YES;

      // NOTE: I'm doing my own special bit of handling of cancelling.  I'm not yet sure
      // that I've successfully guarded all race conditions whereby only one of completed/
      // failed/cancelled callback will get called.
      AFURLConnectionOperation* operation = [[[queues_ objectForKey:queueName] operations] objectAtIndex:index];
      if (!operation.isFinished) {
        // NOTE: this won't work if we send immutable items out of interface
        item.state = DownloadItemStateCancelled;
        
        [operation cancel];
        isCancelled = YES;

        NSUInteger orderInQueue = index;
        [items removeObjectAtIndex:index];
        if (0 == [items count]) {
          orderInQueue = NSNotFound; // represents last item removed
        }

        if ([self.delegate respondsToSelector:@selector(downloader:queue:didCancelItem:orderInQueue:)]) {
          [self.delegate downloader:self queue:queueName didCancelItem:item orderInQueue:orderInQueue];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadDidCancelEvent
                                                            object:self
                                                          userInfo:@{ DQQueue : queueName,
                                                                       DQItem : item,
                                                               DQOrderInQueue : @(orderInQueue)}];
        // TODO: ??? not sure what I'm forgetting here..
        
      }      
    }
  }];
  
  return isCancelled;
}

//
// Private methods
//

- (NSOperationQueue*) queueWithName:(NSString*)queueName {
  
  NSOperationQueue* queue = [queues_ objectForKey:queueName];
  if (nil == queue) {
    @throw [NSException exceptionWithName:@"FindQueueFailure"
                                   reason:[NSString stringWithFormat:@"Queue %@ doesn't exist", queueName]
                                 userInfo:nil];
  }
  
  return queue;
}

- (BOOL) downloadUrl:(NSURL*)url inQueue:(NSString*)queueName outputFile:(NSURL*)outputFile callback:(void(^)(NSError*, id))completeCallback {
  
  // Get the desired queue.
  NSOperationQueue* queue = [self queueWithName:queueName];
  
  // Create the operation.
  NSURLRequest* request = [NSURLRequest requestWithURL:url];
  AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  
  DownloadItem* item = [DownloadItem itemWithUrl:url];
  NSMutableArray* queueItems = [itemsByQueue_ objectForKey:queueName];
  
  // Create a file that the downloaded data can be written to.
  //NSURL* tempFile = outputFile;
  BOOL outputToFile = (nil != outputFile);
  if (outputToFile) {
    NSOutputStream* outputStream = [NSOutputStream outputStreamToFileAtPath:outputFile.relativePath append:NO];
    operation.outputStream = outputStream;
  }
  
  // Set a progress handler.
  __block id<DownloadQueuesDelegate> blockDelegate = self.delegate;
  [operation setDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
    // just checking this:
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Assuming this returns in main queue");

    // No callbacks if the item is cancelled.
    if (DownloadItemStateCancelled == item.state) {
      return;
    }
    
    float progress = ((float)totalBytesRead) / ((float) totalBytesExpectedToRead);
    item.state = DownloadItemStateInProgress;
    item.progress = progress;
    
    if ([self.delegate respondsToSelector:@selector(downloader:queue:item:orderInQueue:totalBytesRead:totalBytesExpectedToRead:percentComplete:)]) {
      // Callback the delegate.  Hope this happens on the main queue.
      [blockDelegate downloader:self
                          queue:queueName
                           item:item
                   orderInQueue:[queueItems indexOfObject:item]
                 totalBytesRead:totalBytesRead
       totalBytesExpectedToRead:totalBytesExpectedToRead
                percentComplete:progress];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadProgressEvent
                                                        object:self
                                                      userInfo:@{ DQQueue : queueName,
                                                                   DQItem : item,
                                                           DQOrderInQueue : @([queueItems indexOfObject:item]),
                                                         DQTotalBytesRead : @(totalBytesRead),
                                               DQTotalBytesExpectedToRead : @(totalBytesExpectedToRead),
                                                        DQPercentComplete : @(progress) }];
  }];
  
  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    // just checking this:
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Assuming this returns in main queue");
    
    // No callbacks if the item is cancelled.
    if (DownloadItemStateCancelled == item.state) {
      return;
    }
    
    // Store the index before removing
    NSUInteger orderInQueue = [queueItems indexOfObject:item];
    [queueItems removeObject:item];
    if (0 == queueItems.count) {
      orderInQueue = NSNotFound; // represents last item removed
    }
    item.isPaused = NO;
    item.state = DownloadItemStateComplete;
    item.progress = 1.0; // 100%
    
    if (outputToFile) {
      // Call the delegate.
      if ([blockDelegate respondsToSelector:@selector(downloader:queue:item:orderInQueue:didCompleteWithFile:)]) {
        [blockDelegate downloader:self queue:queueName item:item orderInQueue:orderInQueue didCompleteWithFile:outputFile];
      }
      
      [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadDidCompleteEvent
                                                          object:self
                                                        userInfo:@{ DQQueue : queueName,
                                                                     DQItem : item,
                                                             DQOrderInQueue : @([queueItems indexOfObject:item]) }];
      // Call the complete callback.
      completeCallback(nil, outputFile);
      
    } else {
      // Sanity check that the returned object is an NSData*
      if ([responseObject isKindOfClass:[NSData class]]) {
        // Call the delegate.
        if ([blockDelegate respondsToSelector:@selector(downloader:queue:item:orderInQueue:didCompleteWithData:)]) {
          [blockDelegate downloader:self queue:queueName item:item orderInQueue:orderInQueue didCompleteWithData:responseObject];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadDidCompleteEvent
                                                            object:self
                                                          userInfo:@{ DQQueue : queueName,
                                                                       DQItem : item,
                                                               DQOrderInQueue : @([queueItems indexOfObject:item]),
                                                                       DQData : responseObject }];
        // Call the complete callback.
        completeCallback(nil, responseObject);
        
      } else {
        completeCallback([NSError errorWithDomain:@"DLUnknownResponseObject" code:0 userInfo:nil], nil);
      }
    }
    
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    // just checking this:
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Assuming this returns in main queue");
    
    // No callbacks if the item is cancelled.
    if (DownloadItemStateCancelled == item.state) {
      return;
    }
    
    // Store the index before removing
    NSUInteger orderInQueue = [queueItems indexOfObject:item];
    [queueItems removeObject:item];
    if (0 == queueItems.count) {
      orderInQueue = NSNotFound; // represents last item removed
    }
    item.isPaused = NO;
    
    // Call the delegate with the error.
    item.state = DownloadItemStateFailed;
    if ([blockDelegate respondsToSelector:@selector(downloader:queue:item:orderInQueue:didFailWithError:)]) {
      [blockDelegate downloader:self queue:queueName item:item orderInQueue:orderInQueue didFailWithError:error];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadDidFailEvent
                                                        object:self
                                                      userInfo:@{ DQQueue : queueName,
                                                                   DQItem : item,
                                                           DQOrderInQueue : @([queueItems indexOfObject:item]),
                                                                  DQError : error }];
  }];
  
  // Put the operation in the queue.
  [queue addOperation:operation];
  item.state = DownloadItemStatePending; // should change to 'in progress' with first progress callback
  item.isPaused = NO;
  item.progress = 0.0;
  [queueItems addObject:item];
  
  NSUInteger orderInQueue = (1 < queueItems.count) ? (queueItems.count - 1) : NSNotFound;
  if ([self.delegate respondsToSelector:@selector(downloader:queue:didStartItem:orderInQueue:)]) {
    [self.delegate downloader:self queue:queueName didStartItem:item orderInQueue:orderInQueue];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:DQDownloadDidStartEvent
                                                      object:self
                                                    userInfo:@{ DQQueue : queueName,
                                                                 DQItem : item,
                                                         DQOrderInQueue : @(orderInQueue) }];
  return YES;
}

- (void) forItem:(DownloadItem*)item perform:(void (^)(NSString* queueName, AFURLConnectionOperation* operation, NSUInteger orderInQueue))perform {
  [itemsByQueue_ enumerateKeysAndObjectsUsingBlock:^(id queueName, id items, BOOL *stop) {
    NSUInteger index = [items indexOfObject:item];
    if (NSNotFound != index) {
      AFURLConnectionOperation* operation = [[[queues_ objectForKey:queueName] operations] objectAtIndex:index];
      perform(queueName, operation, index);
      *stop = YES;
    }
  }];
}

@end

@implementation DownloadItem (StreamDelegate)

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
  
}

@end
