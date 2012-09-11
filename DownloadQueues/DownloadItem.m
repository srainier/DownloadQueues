//
// DownloadItem.m
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

#import "DownloadItem.h"

@implementation DownloadItem

@synthesize state = state_;
@synthesize isPaused = isPaused_;
@synthesize progress = progress_;
@synthesize url = url_;

- (id) init {
  self = [super init];
  if (nil != self) {
    state_ = DownloadItemStateUnknown;
    isPaused_ = NO;
    progress_ = 0.0;
    url_ = nil;
  }
  return self;
}

+ (DownloadItem*) itemWithUrl:(NSURL*)url {
  return [DownloadItem itemWithUrl:url userInfo:nil];
}

+ (DownloadItem*) itemWithUrl:(NSURL*)url userInfo:(id)userInfo {
  DownloadItem* item = [[DownloadItem alloc] init];
  item.url = url;
  item.userInfo = userInfo;
  return item;
}

@end
