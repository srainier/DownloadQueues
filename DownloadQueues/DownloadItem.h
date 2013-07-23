//
// DownloadItem.h
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

typedef enum {
  DownloadItemStateUnknown,
  DownloadItemStatePending,
  DownloadItemStateInProgress,
  DownloadItemStateComplete,
  DownloadItemStateCancelled,
  DownloadItemStateFailed
} DownloadItemState;

/**
 `DownloadItem` represents an asset being downloaded by a `DownloadQueues` object.
 */
@interface DownloadItem : NSObject

/**
 The current state of the download.
 */
@property (nonatomic) DownloadItemState state;

/**
 The paused state of the download.
 */
@property (nonatomic) BOOL isPaused;

/**
 The percent-complete progress value of the download. This value will be between 0 and 1.
 */
@property (nonatomic) float progress;

/**
 The source url of the download.
 */
@property (nonatomic, strong, readonly) NSURL* url;

/**
 User metadata attached to the download.
 */
@property (nonatomic, strong, readonly) id userInfo;

/**
 Create a new `DownloadItem *` for the input url.
 
 This method does not perform a download of the asset at the url. Instead the caller should use a `DownloadQueues` object to initiate a download and retrieve the corresponding `DownloadItem` object.
 
 @param url The url for the download.
 @return The created `DownloadItem` object.
 */
+ (DownloadItem*) itemWithUrl:(NSURL*)url;

/**
 Create a new `DownloadItem *` for the input url.
 
 This method does not perform a download of the asset at the url. Instead the caller should use a `DownloadQueues` object to initiate a download and retrieve the corresponding `DownloadItem` object.
 
 @param url The url for the download.
 @param userInfo User metadata to attached to the object.
 @return The created `DownloadItem` object.
 */
+ (DownloadItem*) itemWithUrl:(NSURL*)url userInfo:(id)userInfo;

@end
