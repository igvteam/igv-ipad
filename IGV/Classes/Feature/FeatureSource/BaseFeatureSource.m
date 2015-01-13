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
// Created by jrobinso on 8/7/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BaseFeatureSource.h"
#import "FeatureCache.h"
#import "FeatureInterval.h"
#import "IGVContext.h"
#import "TDFFeatureSource.h"
#import "FeatureList.h"
#import "HttpResponse.h"
#import "URLDataLoader.h"
#import "TabixFeatureSource.h"
#import "LMResource.h"
#import "GenomeManager.h"
#import "SEGFeatureSource.h"
#import "BWFeatureSource.h"
#import "Logging.h"
#import "IGVHelpful.h"

@implementation BaseFeatureSource

@synthesize trackProperties = _trackProperties;
@synthesize chrTable = _chrTable;
@synthesize featureCache = _featureCache;
@synthesize filePath = _filePath;
@synthesize indexPath = _indexPath;

- (void)dealloc {

    self.trackProperties = nil;
    self.chrTable = nil;
    self.featureCache = nil;
    self.filePath = nil;
    self.indexPath = nil;

    [super dealloc];
}

- (id)init {

    self = [super init];

    if (nil != self) {
        self.visibilityWindowThreshold = NSIntegerMax;
    }
    return self;
}

- (NSMutableDictionary *)trackProperties {

    if (nil == _trackProperties) {
        self.trackProperties = [NSMutableDictionary dictionary];
    }

    return _trackProperties;
}

- (NSMutableDictionary *)chrTable {

    if (nil == _chrTable) {

        self.chrTable = [NSMutableDictionary dictionary];

        if ([self chromosomeNames] != nil) {

            NSDictionary *chromosomeAliasTable = [GenomeManager sharedGenomeManager].chromosomeAliasTable;

            for (NSString *chromosomeName in [self chromosomeNames]) {

                NSString *chromosomeAlias = [chromosomeAliasTable objectForKey:chromosomeName];

                if (nil != chromosomeAlias) {

                    [self.chrTable setObject:chromosomeName forKey:chromosomeAlias];
                }
            }
        }


    }

    return _chrTable;
}

- (FeatureCache *)featureCache {

    if (nil == _featureCache) {
        self.featureCache = [[[FeatureCache alloc] init] autorelease];
    }

    return _featureCache;
}

#pragma mark -
#pragma mark - FeatureSource Protocol implementation

- (id)featuresForFeatureInterval:(FeatureInterval *)featureInterval {
    return [self.featureCache featureListForFeatureInterval:featureInterval];
}

- (void)clearFeatureCache {
    [self.featureCache clear];
}

- (NSArray *)chromosomeNames {
    ALog(@"%@ does not implement this method", [self class]);
    return nil;
}

- (void)loadFeaturesForInterval:(FeatureInterval *)featureInterval completion:(LoadFeaturesCompletion)completion {
    ALog(@"%@ does not implement this method", [self class]);
}

+ (BaseFeatureSource *)featureSourceWithResource:(LMResource *)resource {

    NSString *path = [[resource.filePath lowercaseString] stringByReplacingOccurrencesOfString:@".gz" withString:@""];
    NSString *pathExtension = [path pathExtension];

    if ([pathExtension isEqualToString:@"tdf"]) {
        return [[[TDFFeatureSource alloc] initWithResource:resource] autorelease];
    }

    BOOL isGzipped = ([resource.filePath rangeOfString:@".gz"].location != NSNotFound);
    if (isGzipped) {
        // Load header for basic info on file (in particular content length)
        HttpResponse *response = [URLDataLoader loadHeaderSynchronousWithPath:[NSString stringWithFormat:@"%@.tbi", resource.filePath]];
        if ([IGVHelpful isValidStatusCode:[response statusCode]]) {
            return [[[TabixFeatureSource alloc] initWithFilePath:resource.filePath] autorelease];
        }
    }

    if ([pathExtension isEqualToString:@"seg"]) {
        return [[[SEGFeatureSource alloc] initWithFilePath:resource.filePath] autorelease];
    }

    if ([pathExtension isEqualToString:@"bw"] || [pathExtension isEqualToString:@"bigwig"]) {
        return [[[BWFeatureSource alloc] initWithFilePath:resource.filePath] autorelease];
    }

    if ([pathExtension isEqualToString:@"bb"] || [pathExtension isEqualToString:@"bigbed"]) {
        return [[[BWFeatureSource alloc] initWithFilePath:resource.filePath] autorelease];
    }

    // Default -- we really should check extensions here to be sure we can handle it
//    return [[[AsciiFeatureSource alloc] initWithFilePath:resource.filePath] autorelease];
    return [[[AsciiFeatureSource alloc] initWithResource:resource] autorelease];

}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self class]];
}

@end