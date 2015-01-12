// 
// The MIT License (MIT)
// 
// 
// Copyright (c) 2014 Broad Institute
// 
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


//
// Created by jrobinso on 7/26/12.
//
// Represents a Resource element from an IGV load-from-server or session file.
// example
//  <Resource name="HSMM H3K4me1" trackLine="viewLimits=0:25" path="http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalHsmmH3k4me1.tdf" color="0,150,0"/>

#import <Foundation/Foundation.h>

@interface NSArray (LMResources)
- (NSSet *)bamResourceSet;
@end

@class SMXMLElement;
@class FileListItem;

@interface LMResource : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *indexPath;
@property (nonatomic) BOOL enabled;

@property (nonatomic, copy) NSString *trackLine;
@property (nonatomic, retain) UIColor *color;

- (NSString *)defaultNameWithFilePath:(NSString *)filePath;
- (NSString *)tableViewCellPath;

+ (id)resourceWithFileListItem:(FileListItem *)fileListItem;
+ (id)resourceWithName:(NSString *)name filePath:(NSString *)filePath;
+ (id)resourceWithElement:(SMXMLElement*) element;
@end