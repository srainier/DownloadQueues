//
// NSFileManager+TempFile.m
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

#import "NSFileManager+TempFile.h"
#import <Foundation/NSString.h>

@implementation NSFileManager (TempFile)

- (NSString*) createTempFileHelper:(int*)fileDescriptor {

  // Create a path to a file in the user's temporary directory.  The six 'X'
  // characters are required by mkstemp used below.
  NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.XXXXXX"];
  
  // Convert the template to a string usable by the file system.
  const char *tempFileTemplateCString = NULL;
  @try {
    tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
  }
  @catch (NSException *exception) {
    if ([NSCharacterConversionException isEqualToString:exception.name]) {
      // someone has some weird characters in their path...
    } else {
      // Uhh....
    }
    *fileDescriptor = -1;
    return nil;
  }
  
  // Copy the template string into a mutable char buffer so that mkstemp can modify it.
  char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
  strcpy(tempFileNameCString, tempFileTemplateCString);
  
  // Create the temporary file
  *fileDescriptor = mkstemp(tempFileNameCString);
  
  // Store the filename in an NSString and remove all references to the c-strings.
  NSString* tempFileName = nil;
  if (-1 != *fileDescriptor) {
    tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString
                                                                               length:strlen(tempFileNameCString)];
  }
  
  free(tempFileNameCString);
  tempFileNameCString = NULL;
  tempFileTemplateCString = NULL;
  
  return tempFileName;
}

- (NSFileHandle*) openTemporaryFile {
  int fileDescriptor = 0;
  [self createTempFileHelper:&fileDescriptor];
  if (-1 != fileDescriptor) {
    // Leave the file open and give the NSFileHandle responsibility for closing it.
    return [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
  } else {
    return nil;
  }
}

- (NSURL*) createTemporaryFile {
  int fileDescriptor = 0;
  NSString* tempFileName = [self createTempFileHelper:&fileDescriptor];

  if (fileDescriptor == -1) {
    tempFileName = nil;
    return nil;
  } else {
    // Close the file and return the path to the (empty) file.
    close(fileDescriptor);
    assert([[NSFileManager defaultManager] fileExistsAtPath:tempFileName]);
    return [NSURL fileURLWithPath:tempFileName];
  }
}

@end
