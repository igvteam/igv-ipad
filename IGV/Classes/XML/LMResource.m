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
// To change the template use AppCode | Preferences | File Templates.
//
//  <Resource name="HSMM H3K4me1" trackLine="viewLimits=0:25" path="http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalHsmmH3k4me1.tdf" color="0,150,0"/>


#import "LMResource.h"
#import "SMXMLDocument.h"
#import "FileListItem.h"
#import "IGVHelpful.h"

@implementation NSArray (LMResources)
- (NSSet *)bamResourceSet {

    NSMutableSet *bam = [NSMutableSet set];
    for (LMResource *resource in self) {

        if ([[resource.filePath pathExtension] isEqualToString:@"bam"]) {
            [bam addObject:resource];
        }

    }

    return bam;
}
@end

@interface LMResource ()
- (id)initWithElement:(SMXMLElement *)element;
- (id)initWithFileListItem:(FileListItem *)fileListItem;

- (id)initWithName:(NSString *)name filePath:(NSString *)filePath indexPath:(NSString *)indexPath;
- (NSString *)resourceNameWithString:(NSString *)string filePath:(NSString *)filePath;
@end

@implementation LMResource

@synthesize name = _name;
@synthesize filePath = _filePath;
@synthesize indexPath = _indexPath;
@synthesize enabled = _enabled;

@synthesize trackLine = _trackLine;
@synthesize color = _color;

- (void)dealloc {

    self.name = nil;
    self.indexPath = nil;
    self.filePath = nil;

    self.trackLine = nil;
    self.color = nil;

    [super dealloc];
}

- (id)initWithElement:(SMXMLElement *)element {

    self = [super init];

    if (nil != self) {

        self.enabled = NO;
        self.filePath = [element attributeNamed:@"path"];
        self.name = [self resourceNameWithString:[element attributeNamed:@"name"] filePath:[element attributeNamed:@"path"]];

        // For old version 1 formats
        if(nil == self.filePath) {
            self.filePath = self.name;
        }

        self.color = [IGVHelpful colorWithCommaSeparateRGBString:[element attributeNamed:@"color"]];
        self.trackLine = [element attributeNamed:@"trackLine"];
    }

    return self;
}

- (id)initWithFileListItem:(FileListItem *)fileListItem {

    self = [super init];

    if (nil != self) {
        
        self.enabled = fileListItem.enabled;
        self.name = [self resourceNameWithString:fileListItem.label filePath:fileListItem.filePath];
        self.filePath = fileListItem.filePath;
        self.indexPath = fileListItem.indexPath;
    }

    return self;
}

- (id)initWithName:(NSString *)name filePath:(NSString *)filePath indexPath:(NSString *)indexPath {

    self = [super init];
    if (nil != self) {

        self.filePath = filePath;
        self.indexPath = indexPath;
        self.enabled = NO;
        self.name = [self resourceNameWithString:name filePath:filePath];
    }

    return self;
}

- (NSString *)resourceNameWithString:(NSString *)string filePath:(NSString *)filePath {
    return ([string isEqualToString:@""] || nil == string) ? [self defaultNameWithFilePath:filePath] : string;
}

- (NSString *)defaultNameWithFilePath:(NSString *)filePath {

    NSArray *parts = [filePath componentsSeparatedByString:@"/"];
    NSString *defaultName = [parts objectAtIndex:([parts count] - 1)];

    return defaultName;
}

- (NSString *)tableViewCellPath {

    NSArray *parts = [self.filePath componentsSeparatedByString:@"://"];
    NSString *str = [parts objectAtIndex:([parts count] - 1)];

    return str;
}

//- (void)setEnabled:(BOOL)enabled {
//
//    _enabled = enabled;
//    if (nil != self.fileListItem) {
//        self.fileListItem.enabled = enabled;
//    }
//
//}

+ (id)resourceWithFileListItem:(FileListItem *)fileListItem {
    return [[[LMResource alloc] initWithFileListItem:fileListItem] autorelease];
}

+ (id)resourceWithName:(NSString *)name filePath:(NSString *)filePath indexPath:(NSString *)indexPath {
    return [[[LMResource alloc] initWithName:name filePath:filePath indexPath:indexPath] autorelease];
}

+ (id)resourceWithElement:(SMXMLElement *)element {
    return [[[LMResource alloc] initWithElement:element] autorelease];
}

- (NSString *)description {

    return [NSString stringWithFormat:@"%@. enabled %@. color %@. name %@. path %@", [self class], self.enabled ? @"YES" : @"NO", self.color, self.name, self.filePath];
//    return [NSString stringWithFormat:@"%@ name %@ path %@", [self class], self.name, self.path];
}

@end