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
// Created by jrobinso on 7/29/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FeatureCache.h"
#import "FeatureList.h"
#import "FeatureInterval.h"
#import "Logging.h"
#import "IGVHelpful.h"

@interface FeatureCache ()

@end

@implementation FeatureCache

@synthesize featureListDictionary;

- (void)dealloc {
    self.featureListDictionary = nil;
    [super dealloc];
}


- (id)init {
    self = [self initWithZoomOption:NO];
    return self;
}

- (id)initWithZoomOption:(BOOL)zoomAware {

    self = [super init];
    if (nil != self) {
        self.loadComplete = NO;
        self.zoomAware = zoomAware;
        self.featureListDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}


// Return the cached feature list for this interval, if any.  This method does not trigger loads, if there is no
// list for the interval in the cache nil is returned.
- (FeatureList *)featureListForFeatureInterval:(FeatureInterval *)featureInterval {

    NSArray *featureLists = [self.featureListDictionary objectForKey:featureInterval.chromosomeName];

    if (nil != featureLists) {

        for (FeatureList *featureList in featureLists) {

            if (nil == featureList) continue;

            NSInteger zoomLevel = self.zoomAware ? featureInterval.zoomLevel : -1;
            if ([featureList.featureInterval containsChromosomeName:featureInterval.chromosomeName
                                                              start:featureInterval.start
                                                                end:featureInterval.end
                                                          zoomLevel:zoomLevel]) {

                return featureList;

            }
        }
    }

    return self.loadComplete ? [FeatureList emptyFeatureListForChromosome:featureInterval.chromosomeName] : nil;
}


- (BOOL)cacheHitWithFeatureInterval:(FeatureInterval *)featureInterval {
    return NO;
}

- (void)addFeatureList:(FeatureList *)featureList {

    NSMutableArray *featureLists = [self.featureListDictionary objectForKey:featureList.featureInterval.chromosomeName];

    if (nil == featureLists) {

        featureLists = [NSMutableArray array];
        [self.featureListDictionary setObject:featureLists forKey:featureList.featureInterval.chromosomeName];
    }

    [featureLists addObject:featureList];

}

- (NSArray *) chromosomeNames {
    if(nil == self.featureListDictionary) return nil;
    else return self.featureListDictionary.allKeys;
}

- (BOOL)isEmpty {
    return self.featureListDictionary.count == 0;
}

- (NSString *)description {

    NSString *string = (0 == [self.featureListDictionary count]) ? @"0" : [NSString stringWithFormat:@"%@", self.featureListDictionary];
    return [NSString stringWithFormat:@"%@. feature dictionary %@", [self class], string];
}

- (void)clear {
    self.loadComplete = NO;
    [self.featureListDictionary removeAllObjects];

}
@end