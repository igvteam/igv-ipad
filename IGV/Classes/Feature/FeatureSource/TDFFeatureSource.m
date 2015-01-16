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
// Created by jrobinso on 7/20/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "TDFFeatureSource.h"
#import "TDFReader.h"
#import "TDFDataset.h"
#import "FeatureList.h"
#import "TDFTile.h"
#import "TDFGroup.h"
#import "DataScale.h"
#import "ParsingUtils.h"
#import "FeatureInterval.h"
#import "FeatureCache.h"
#import "TrackView.h"
#import "HttpResponse.h"
#import "Logging.h"
#import "IGVHelpful.h"
#import "IGVAppDelegate.h"
#import "UIApplication+IGVApplication.h"
#import "LMResource.h"

@interface TDFFeatureSource ()
@property(nonatomic, retain) UIColor *color;
@end

@implementation TDFFeatureSource

@synthesize reader = _reader;
@synthesize trackName = _trackName;
@synthesize maxZoom = _maxZoom;
@synthesize color = _color;

- (void)dealloc {

    self.reader = nil;
    self.trackName = nil;
    self.color = nil;

    [super dealloc];
}

- (id)initWithFilePath:(NSString *)filePath {

    self = [super init];

    if (nil != self) {
        self.filePath = filePath;
        self.featureCache = [[[FeatureCache alloc] initWithZoomOption:YES] autorelease];
    }

    return self;
}

- (id)initWithResource:(LMResource *)resource {

    self = [super init];

    if (nil != self) {
        self.color = resource.color;
        self.filePath = resource.filePath;
        self.featureCache = [[[FeatureCache alloc] initWithZoomOption:YES] autorelease];
    }

    return self;
}

- (void)loadFeaturesForInterval:(FeatureInterval *)featureInterval completion: (LoadFeaturesCompletion) completion {

    if (nil == self.reader) {

        self.reader = [[[TDFReader alloc] initWithPath:self.filePath completion:^(HttpResponse *response) {

            if ([IGVHelpful errorDetected:response.error]) {

                ALog(@"ERROR %@", [(response.error) localizedDescription]);

                [self.featureCache addFeatureList:[FeatureList emptyFeatureListForInterval:featureInterval]];
                completion();
                return;
            }

            // TODO - dat - Currently only handling single track of potentially multi-track file
            self.trackName = [self.reader.trackNames objectAtIndex:0];

            if (self.reader.trackLine != nil && ![self.reader.trackLine isEqualToString:@""]) {
                self.trackProperties = [ParsingUtils parseTrackLine:self.reader.trackLine];
            }

            if (nil != self.color) {
                [self.trackProperties setObject:self.color forKey:@"color"];
            }

            [self selfParseGroupAttributes:[TDFGroup tdfGroupWithName:@"/" data:response.receivedData]];

            // Try again.  TODO - What prevents an infinite loop?
            [self _loadFeaturesForInterval:featureInterval completion:completion];

        }] autorelease];

    } else {

        [self _loadFeaturesForInterval:featureInterval completion: completion];
    }

}

- (void)_loadFeaturesForInterval:(FeatureInterval *)featureInterval completion: (LoadFeaturesCompletion) completion {

    dispatch_async([UIApplication sharedIGVAppDelegate].featureSourceQueue, ^{


        // 1.  get query featureInterval
        // 2.  infer zoomLevel level
        // 3.  load overlapping tiles
        // 4.  fetch features from tiles.

        NSString *queryChr = [self.chrTable objectForKey:featureInterval.chromosomeName];
        if (nil == queryChr) {
            queryChr = featureInterval.chromosomeName;
        }

        // TODO -- remove this when startLocation bounds is enforced in IGVContext
        long long startLocation = MAX(0, featureInterval.start);
        long long endLocation = featureInterval.end;

        NSError *error = nil;
        NSString *windowFunction = @"mean";   // TODO

        // By convention use maxZoom + 1 => raw (non pre-processed) data
        BOOL loadRaw = featureInterval.zoomLevel > _maxZoom;

        int effectiveZoom = MIN(featureInterval.zoomLevel, _maxZoom + 1);

        TDFDataset *dataSet = [self.reader loadDatasetForChromosome:queryChr zoom:effectiveZoom windowFunction:windowFunction error:&error];

        if ([IGVHelpful errorDetected: error]) {

            ALog(@"ERROR %@", [error localizedDescription]);
            [self.featureCache addFeatureList:[FeatureList emptyFeatureListForInterval:featureInterval]];
            completion();
        }

        NSInteger startTile = (NSInteger) floor(startLocation / dataSet.tileWidth);
        NSInteger endTile = (NSInteger) floor(endLocation / dataSet.tileWidth);

        int queryStart = (int) (startTile * dataSet.tileWidth);
        int queryEnd = (int) (endTile * dataSet.tileWidth + dataSet.tileWidth);

        NSMutableArray *features = [NSMutableArray array];

        for (int tileNumber = startTile; tileNumber <= endTile; tileNumber++) {

            id <TDFTile> tile = [self.reader tileForDataset:dataSet number:tileNumber];

            if (nil == tile) continue;

            NSArray *featureArray = [tile featuresForTrack:self.trackName];

            [features addObjectsFromArray:featureArray];
        }

        int cacheZoom = loadRaw ? -1 : featureInterval.zoomLevel;

        // For indexed sources, such as TDF, we keep at most 1 feature list in the cache.  This is a bit of a hack
        [self.featureCache clear];

        FeatureInterval *f = [FeatureInterval intervalWithChromosomeName:featureInterval.chromosomeName start:queryStart end:queryEnd zoomLevel:cacheZoom];
        [self.featureCache addFeatureList:[FeatureList featureListForFeatureInterval:f features:features]];

        completion();
    });


}


- (NSArray *)chromosomeNames {

    NSMutableArray *nameArray = [NSMutableArray arrayWithCapacity:self.reader.chromosomeNames.count];
    for (NSString *chromosomeName in self.reader.chromosomeNames) {
        [nameArray addObject:chromosomeName];
    }

    return nameArray;
}

- (void)selfParseGroupAttributes:(TDFGroup *)tdfGroup {

    if (nil == tdfGroup.attributes) {

        return;
    }

    if (nil == [self.trackProperties objectForKey:@"viewLimits"]) {
        NSString *maxValueString = [tdfGroup.attributes objectForKey:@"98th Percentile"];
        if (nil == maxValueString) {
            maxValueString = [tdfGroup.attributes objectForKey:@"Maximum"];
        }
        NSString *minValueString = [tdfGroup.attributes objectForKey:@"2nd Percentile"];
        if (nil == minValueString) {
            minValueString = [tdfGroup.attributes objectForKey:@"Minimum"];
        }

        if (nil != minValueString && nil != maxValueString) {
            float lowerValue = [minValueString floatValue];
            float upperValue = [maxValueString floatValue];
            DataScale *scale = [[[DataScale alloc] initWithMin:lowerValue max:upperValue] autorelease];
            [self.trackProperties setObject:scale forKey:@"viewLimits"];
        }
    }

    if (nil != [tdfGroup.attributes objectForKey:@"maxZoom"]) {
        self.maxZoom = [[tdfGroup.attributes objectForKey:@"maxZoom"] integerValue];
    }

}

- (NSString *)description {

    return [NSString stringWithFormat:@"%@. %@. path %@.", [self class], [self.reader class], self.filePath];
}

@end
