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
//  Created by turner on 2/6/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "FileListItem.h"

@implementation FileListItem
@synthesize filePath = _filePath;
@synthesize indexPath = _indexPath;
@synthesize label = _label;
@synthesize enabled = _enabled;
@synthesize genome = _genome;

- (void) dealloc {

    self.filePath = nil;
    self.indexPath = nil;
    self.label = nil;
    self.genome = nil;

    [super dealloc];
}

- (id)initWithFilePath:(NSString *)filePath label:(NSString *)label genome:(NSString *)genome {

    self = [super init];

    if (nil != self) {

        self.enabled = NO;
        self.filePath = filePath;
        self.label = ([label isEqualToString:@""] || nil == label) ? [FileListItem defaultLabelWithFilePath:filePath] : label;
        self.genome = genome;
    }

    return self;
}

+ (NSString *)defaultLabelWithFilePath:(NSString *)filePath {

//    NSArray *parts = [path componentsSeparatedByString:@"/"];
//    NSString *filename = [parts objectAtIndex:([parts count] - 1)];
//    return filename;

    return @"untitled";
}

#pragma mark - NSUserDefaults helper methods

- (NSDictionary *)fileListDefaultsItem {

//    return [NSDictionary dictionaryWithObject:self.label forKey:self.path];
    return [NSDictionary dictionaryWithObject:self.label forKey:[self userDefaultsKey]];
}

- (NSString *)userDefaultsKey {
    return [NSString stringWithFormat:@"%@#%@", self.genome, self.filePath];
}

+ (NSString *)labelWithFileListDefaultsItem:(NSDictionary *)fileListDefaultsItem {

    NSString *key = [[fileListDefaultsItem allKeys] objectAtIndex:0];
    return [fileListDefaultsItem objectForKey:key];
}

+ (NSString *)filePathWithFileListDefaultsItem:(NSDictionary *)fileListDefaultsItem {
    return [self stringWithFileListDefaultsItem:fileListDefaultsItem index:1];
}

+ (NSString *)genomeWithFileListDefaultsItem:(NSDictionary *)fileListDefaultsItem {
    return [self stringWithFileListDefaultsItem:fileListDefaultsItem index:0];
}

+ (NSString *)stringWithFileListDefaultsItem:(NSDictionary *)fileListDefaultsItem index:(NSUInteger)index {

    NSString *key = [[fileListDefaultsItem allKeys] objectAtIndex:0];
    NSArray *parts = [key componentsSeparatedByString:@"#"];

    return [parts objectAtIndex:index];
}

#pragma mark - Table view delegate methods

- (NSString *)tableViewCellLabel {
    return self.label;
}

- (NSString *)tableViewCellURL {

    NSArray *parts = [self.filePath componentsSeparatedByString:@"://"];
    NSString *str = [parts objectAtIndex:([parts count] - 1)];

    return str;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"enabled: %@ label: %@", self.enabled ? @"YES" : @"NO", self.label];
}

@end