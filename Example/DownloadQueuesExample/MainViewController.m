//
// MainViewController.m
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

#import "MainViewController.h"
#import "DownloadQueues.h"
#import "DownloadItem.h"
#import "KeyedFileStorage.h"

const NSInteger IN_PROGRESS_LABEL_TAG = 0x1001;
const NSInteger IN_PROGRESS_PROGRESS_TAG = 0x1002;

@interface MainViewController () {
  NSMutableArray* completedDownloads_;
  NSMutableArray* completedDownloadKeys_;
  DownloadQueues* downloader_;
}

@property (nonatomic, retain) IBOutlet UITextField* urlInput;
@property (nonatomic, retain) IBOutlet UITableView* downloadsTable;

- (DownloadItem*) itemForIndexPath:(NSIndexPath*)indexPath;

@end

@interface MainViewController (DownloadDelegate) <DownloadQueuesDelegate>
@end

@interface MainViewController (UrlTextInput) <UITextFieldDelegate>
@end

@interface MainViewController (DownloadsTable) <UITableViewDelegate, UITableViewDataSource>
@end

@implementation MainViewController

@synthesize urlInput = urlInput_;
@synthesize downloadsTable = downloadsTable_;

- (id)init {
  self = [super init];
  if (self) {
    downloader_ = [[DownloadQueues alloc] init];
    downloader_.delegate = self;
    [downloader_ createQueueWithName:@"Main Queue" maxConcurrentDownloads:2];
    completedDownloads_ = [NSMutableArray array];
    completedDownloadKeys_ = [NSMutableArray array];
    
    // Don't do this here in real apps:
    [[KeyedFileStorage defaultStorage] createInDocumentsSubdirectoryWithName:@"Downloader" error:nil];
  }
  return self;
}

- (void) viewDidLoad {
  [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//
// Private methods
//

- (DownloadItem*) itemForIndexPath:(NSIndexPath*)indexPath {
  if (0 == indexPath.section) {
    return [completedDownloads_ objectAtIndex:indexPath.row];
  } else {
    NSString* queueName = [[downloader_ allQueueNames] objectAtIndex:indexPath.section - 1];
    NSArray* queueItems = [downloader_ itemsInQueue:queueName];
    return [queueItems objectAtIndex:indexPath.row];
  }
}

@end

@implementation MainViewController (UrlTextInput)

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  [downloader_ downloadUrl:[NSURL URLWithString:textField.text]
                   inQueue:@"Main Queue"
                    toFile:^(NSError *error, NSURL *url) {
                      
                    }];
  return YES;
}

@end

@implementation MainViewController (DownloadsTable)


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
  
  __block NSUInteger activeQueues = 0;
  [[downloader_ allQueueNames] enumerateObjectsUsingBlock:^(id queueName, NSUInteger idx, BOOL *stop) {
    activeQueues += ([downloader_ itemsInQueue:queueName].count == 0 ? 0 : 1);
  }];
  
  return 1 + activeQueues;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (0 == section) {
    return @"Completed";
  } else {
    return [[downloader_ allQueueNames] objectAtIndex:section - 1];
  }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (0 == section) {
    return completedDownloads_.count;
  } else {
    return [[downloader_ itemsInQueue:[[downloader_ allQueueNames] objectAtIndex:section - 1]] count];
  }
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  BOOL inProgress = (0 != indexPath.section);
  
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:inProgress ? @"in-progress" : @"complete"];
  
  if (nil == cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:inProgress ? @"in-progress" : @"complete"];
    
    if (inProgress) {
      CGRect textFrame = cell.contentView.bounds;
      textFrame.size.height /= 2.0;
      UILabel* label = [[UILabel alloc] initWithFrame:textFrame];
      label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
      label.text = @"initialize me";
      label.tag = IN_PROGRESS_LABEL_TAG;
      [cell.contentView addSubview:label];
      
      CGRect progressFrame = cell.contentView.bounds;
      progressFrame.size.height /= 2.0;
      progressFrame.origin.y += progressFrame.size.height;
      UIProgressView* progress = [[UIProgressView alloc] initWithFrame:progressFrame];
      progress.progress = 0.5;
      progress.tag = IN_PROGRESS_PROGRESS_TAG;
      [cell.contentView addSubview:progress];
    }
  }
  
  cell.textLabel.text = nil;
  
  if (0 == indexPath.section) {
    DownloadItem* completedDownload = [completedDownloads_ objectAtIndex:indexPath.row];
    if (completedDownload.state == DownloadItemStateComplete) {
      cell.textLabel.text =  @"Success";
    } else if (completedDownload.state == DownloadItemStateCancelled) {
      cell.textLabel.text = @"Cancelled";
    } else {
      cell.textLabel.text = @"Failed";
    }
    cell.detailTextLabel.text = completedDownload.url.relativeString;
  } else {
    
    DownloadItem* item = [self itemForIndexPath:indexPath];
    [(UILabel*)[cell.contentView viewWithTag:IN_PROGRESS_LABEL_TAG] setText:item.url.relativeString];
    [(UIProgressView*)[cell.contentView viewWithTag:IN_PROGRESS_PROGRESS_TAG] setProgress:item.progress];
  }
  
  return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (0 != indexPath.section) {
    DownloadItem* item = [self itemForIndexPath:indexPath];
    if ([downloader_ isItemPaused:item]) {
      [downloader_ resumeItem:item];
    } else {
      [downloader_ pauseItem:item];
    }
  }
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return 0 < indexPath.section;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [downloader_ cancelItem:[self itemForIndexPath:indexPath]];
  }
}

@end

@implementation MainViewController (DownloadDelegate)


- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue
     totalBytesRead:(long long)totalBytesRead
totalBytesExpectedToRead:(long long)totalBytesExpectedToRead
    percentComplete:(float)percentComplete {

  NSUInteger section = [[downloader_ allQueueNames] indexOfObject:queueName] + 1;
  NSUInteger row = orderInQueue;
  
  UITableViewCell* cell = [self.downloadsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
  [(UIProgressView*)[cell.contentView viewWithTag:IN_PROGRESS_PROGRESS_TAG] setProgress:percentComplete];

  // Could always try reloading just the cell
  /*
  [self.downloadsTable beginUpdates];
  [self.downloadsTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section]] withRowAnimation:UITableViewRowAnimationAutomatic];
  [self.downloadsTable endUpdates];*/

}

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
       didStartItem:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue {

  NSUInteger section = [[downloader_ allQueueNames] indexOfObject:queueName] + 1;

  [self.downloadsTable beginUpdates];
  
  if (NSNotFound == orderInQueue) {
    // increment section index to account for 'completed' section.
    [self.downloadsTable insertSections:[NSIndexSet indexSetWithIndex:section]
                       withRowAnimation:UITableViewRowAnimationAutomatic];
  } else {
    [self.downloadsTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:orderInQueue inSection:section]]
                               withRowAnimation:UITableViewRowAnimationAutomatic];
  }
  
  [self.downloadsTable endUpdates];
}

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
       didPauseItem:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue {
  // Not handling yet
}

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
      didResumeItem:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue {
  // Not handling yet  
}

- (void) item:(DownloadItem*)item
completedSuccessfully:(BOOL)success
        queue:(NSString*)queueName
 orderInQueue:(NSUInteger)orderInQueue {
  
  NSUInteger completedDownloadIndex = completedDownloads_.count;
  [completedDownloads_ addObject:item];
  // NOTE: storage of file (and addition to completedDownloadKeys_) could get
  // out of sync with completedDownloads_ and the table.  Don't do this in
  // production.
  // For now, just add NSNull.
  [completedDownloadKeys_ addObject:[NSNull null]];
  
  NSUInteger section = [[downloader_ allQueueNames] indexOfObject:queueName] + 1;
  
  [self.downloadsTable beginUpdates];
  [self.downloadsTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:completedDownloadIndex inSection:0]]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
  if (NSNotFound == orderInQueue) {
    [self.downloadsTable deleteSections:[NSIndexSet indexSetWithIndex:section]
                       withRowAnimation:UITableViewRowAnimationAutomatic];
  } else {
    [self.downloadsTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:orderInQueue inSection:section]]
                               withRowAnimation:UITableViewRowAnimationAutomatic];
  }
  [self.downloadsTable endUpdates];
}

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
      didCancelItem:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue {
    
  [self item:item completedSuccessfully:NO queue:queueName orderInQueue:orderInQueue];
}

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue
didCompleteWithData:(NSData *)data {

  [self item:item completedSuccessfully:YES queue:queueName orderInQueue:orderInQueue];
}

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue
didCompleteWithFile:(NSURL *)file {
  
  [self item:item completedSuccessfully:YES queue:queueName orderInQueue:orderInQueue];

  NSError* error = nil;
  NSString* newItemKey = [[KeyedFileStorage defaultStorage] storeNewFile:file error:&error];
  if (nil == newItemKey) {
    NSLog(@"Failed to store file %@", item.url);
  } else {
    [completedDownloadKeys_ replaceObjectAtIndex:completedDownloadKeys_.count - 1 withObject:newItemKey];
  }
}

- (void) downloader:(DownloadQueues*)downloader
              queue:(NSString*)queueName
               item:(DownloadItem *)item
       orderInQueue:(NSUInteger)orderInQueue
   didFailWithError:(NSError *)error {
  
  [self item:item completedSuccessfully:NO queue:queueName orderInQueue:orderInQueue];
}

@end
