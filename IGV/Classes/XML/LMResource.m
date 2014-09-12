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

        if ([[resource.path pathExtension] isEqualToString:@"bam"]) {
            [bam addObject:resource];
        }

    }

    return bam;
}
@end

@interface LMResource ()
@property(nonatomic, retain) FileListItem *fileListItem;
- (id)initWithElement:(SMXMLElement *)element;

- (NSString *)resourceNameWithString:(NSString *)string path:(NSString *)path;

- (id)initWithFileListItem:(FileListItem *)fileListItem;
- (id)initWithName:(NSString *)name path:(NSString *)path;
@end

@implementation LMResource

@synthesize name = _name;
@synthesize path = _path;
@synthesize trackLine = _trackLine;
@synthesize color = _color;
@synthesize enabled = _enabled;
@synthesize fileListItem = _fileListItem;

- (void)dealloc {
    self.name = nil;
    self.path = nil;
    self.trackLine = nil;
    self.color = nil;
    self.fileListItem = nil;

    [super dealloc];
}

- (id)initWithElement:(SMXMLElement *)element {

    self = [super init];

    if (nil != self) {

        self.enabled = NO;
        self.path = [element attributeNamed:@"path"];
        self.name = [self resourceNameWithString:[element attributeNamed:@"name"] path:[element attributeNamed:@"path"]];

        // For old version 1 formats
        if(nil == self.path) {
            self.path = self.name;
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
        self.fileListItem = fileListItem;
        self.name = [self resourceNameWithString:fileListItem.label path:fileListItem.path];
        self.path = fileListItem.path;
    }

    return self;
}

- (id)initWithName:(NSString *)name path:(NSString *)path {

    self = [super init];
    if (nil != self) {

        self.path = path;
        self.enabled = NO;
        self.name = [self resourceNameWithString:name path:path];
    }

    return self;
}

- (NSString *)resourceNameWithString:(NSString *)string path:(NSString *)path {
    return ([string isEqualToString:@""] || nil == string) ? [self defaultNameWithPath:path] : string;
}

- (NSString *)defaultNameWithPath:(NSString *)path {

    NSArray *parts = [path componentsSeparatedByString:@"/"];
    NSString *defaultName = [parts objectAtIndex:([parts count] - 1)];

    return defaultName;
}

- (NSString *)tableViewCellPath {

    NSArray *parts = [self.path componentsSeparatedByString:@"://"];
    NSString *str = [parts objectAtIndex:([parts count] - 1)];

    return str;
}

- (void)setEnabled:(BOOL)enabled {

    _enabled = enabled;
    if (nil != self.fileListItem) {
        self.fileListItem.enabled = enabled;
    }

}

+ (id)resourceWithFileListItem:(FileListItem *)fileListItem {
    return [[[LMResource alloc] initWithFileListItem:fileListItem] autorelease];
}

+ (id)resourceWithName:(NSString *)name path:(NSString *)path {
    return [[[LMResource alloc] initWithName:name path:path] autorelease];
}

+ (id)resourceWithElement:(SMXMLElement *)element {
    return [[[LMResource alloc] initWithElement:element] autorelease];
}

- (NSString *)description {

    return [NSString stringWithFormat:@"%@. enabled %@. color %@. name %@. path %@", [self class], self.enabled ? @"YES" : @"NO", self.color, self.name, self.path];
//    return [NSString stringWithFormat:@"%@ name %@ path %@", [self class], self.name, self.path];
}

@end