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
// Created by turner on 4/3/14.
//

#import "PListPersistence.h"
#import "Logging.h"

NSString *const PListSuffix = @"plist";

@interface PListPersistence ()
@property(nonatomic, copy) NSString *pListPrefix;
@property(nonatomic, copy) NSString *plistDocumentsPath;
@property(nonatomic, copy) NSString *plistBundlePath;
@end

@implementation PListPersistence

@synthesize plistDocumentsPath = _plistDocumentsPath;
@synthesize pListPrefix = _pListPrefix;
@synthesize plistBundlePath = _plistBundlePath;

- (void)dealloc {

    self.pListPrefix = nil;
    self.plistDocumentsPath = nil;
    self.plistBundlePath = nil;

    [super dealloc];
}

+(PListPersistence *)sharedPListPersistence {

    static dispatch_once_t pred;
    static PListPersistence *shared = nil;

    dispatch_once(&pred, ^{

        shared = [[PListPersistence alloc] init];
    });

    return shared;
}

- (BOOL)initializePersistenceWithPlistInBundlePrefix:(NSString *)prefix error:(NSError **)error {

    NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [root stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", prefix, PListSuffix]];

    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];

    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {

        if (![fileManager removeItemAtPath:path error:error]) {
            return NO;
        }
    }

    BOOL success = NO;
    self.pListPrefix = prefix;
    self.plistDocumentsPath = path;
    self.plistBundlePath = [[NSBundle mainBundle] pathForResource:self.pListPrefix ofType:PListSuffix];

    success = [fileManager copyItemAtPath:self.plistBundlePath toPath:self.plistDocumentsPath error:error];
    return success;
}

- (BOOL)usePListPrefix:(NSString *)prefix {

    BOOL success = YES;

    NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [root stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", prefix, PListSuffix]];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:prefix ofType:PListSuffix];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {

        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        NSError *error = nil;
        success = [fileManager copyItemAtPath:bundlePath toPath:path error:&error];

        if (!success) {
            return NO;
        }
    }

    self.pListPrefix = prefix;
    self.plistDocumentsPath = path;
    self.plistBundlePath = bundlePath;

    return success;
}

- (NSMutableDictionary *)plistDictionary {
    return [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:self.plistDocumentsPath]];
}

- (void)writePListDictionary:(NSDictionary *)dictionary {
    [dictionary writeToFile:self.plistDocumentsPath atomically:YES];
}

+ (NSMutableDictionary *)plistDictionaryInBundleWithPrefix:(NSString *)pListPrefix {

    NSString *plistBundlePath = [[NSBundle mainBundle] pathForResource:pListPrefix ofType:PListSuffix];

    NSString *errorDescription = nil;
    NSPropertyListFormat ignore;
    NSMutableDictionary *plistDictionary = (NSMutableDictionary *) [NSPropertyListSerialization propertyListFromData:[[NSFileManager defaultManager] contentsAtPath:plistBundlePath]
                                                                                                    mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                                                                              format:&ignore
                                                                                                    errorDescription:&errorDescription];

    return (nil == errorDescription) ? plistDictionary : nil;

}

@end