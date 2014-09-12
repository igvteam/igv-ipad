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
//  FeatureSource.m
//  IGV
//
//  Created by Douglass Turner on 5/11/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "AsciiFeatureSource.h"
#import "Logging.h"
#import "CodecFactory.h"
#import "Codec.h"
#import "NSData+GZIP.h"
#import "FeatureList.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "LinearIndex.h"
#import "IndexFactory.h"
#import "ChrIndex.h"
#import "FileRange.h"
#import "FeatureCache.h"
#import "FeatureInterval.h"
#import "ParsingUtils.h"
#import "LittleEndianByteBuffer.h"
#import "TrackView.h"
#import "IGVHelpful.h"
#import "Feature.h"
#import "IGVContext.h"
#import "NSArray+Cytoband.h"
#import "BWTotalSummary.h"
#import "WIGCodec.h"
#import "WIGFeature.h"
#import "LMResource.h"
#import "GenomeManager.h"


@interface AsciiFeatureSource ()
@property(nonatomic) long long int gzipped;
@end

@implementation AsciiFeatureSource

@synthesize codec;
@synthesize path = _path;
@synthesize featureIndex;
@synthesize trackProperties;
@synthesize bwTotalSummary = _bwTotalSummary;
@synthesize indexLoadAttempts = _indexLoadAttempts;

- (void)dealloc {

    self.path = nil;
    self.codec = nil;
    self.featureIndex = nil;
    self.trackProperties = nil;
    self.bwTotalSummary = nil;

    [super dealloc];
}

- (id)initWithPath:(NSString *)path {

    self = [super init];

    if (nil != self) {
        self.indexLoadAttempts = 0;
        self.path = path;
        self.codec = [[CodecFactory sharedCodecFactory] codecForPath:path];
        self.bwTotalSummary = [[BWTotalSummary alloc] autorelease];
    }

    return self;
}

- (id)featuresForFeatureInterval:(FeatureInterval *)featureInterval {

    FeatureList *featureList = [self.featureCache featureListForFeatureInterval:featureInterval];

    if (nil != featureList && featureList.featureInterval.length > 0) {
        // Override min & max with computed stats
        BWTotalSummary *summary = self.bwTotalSummary;
        double range = 2 * summary.stddev;

        if (summary.minVal >= 0) {
            // All (+) values
            featureList.minScore = 0;
            featureList.maxScore = MIN (summary.maxVal, summary.mean + range);
        }
        else if (summary.maxVal <= 0) {
            // All (-) values
            featureList.maxScore = 0;
            featureList.minScore = summary.mean - range;
        }
        else {
            // Both + and - values.  // TODO -- we don't render this correctly, need a line through 0
            double maxAbs = MAX(fabs(summary.minVal), summary.maxVal);
            range = MIN(range, maxAbs);
            featureList.minScore = -range;
            featureList.maxScore = range;
        }
    }
    return featureList;

}


//
//  Load (or retrieve from cache) features for the requested interval and signal completion with a callback
//
- (void)loadFeaturesForInterval:(FeatureInterval *)interval
                     completion:(LoadFeaturesCompletion)completion {

    FeatureList *featureList = [self featuresForFeatureInterval:interval];

    if (nil != featureList) {
        completion();   // We're done
    }
    else {

        if (_indexLoadAttempts == 0) {
            // Try to load an index first
            _indexLoadAttempts++;
            NSString *indexPath = [NSString stringWithFormat:@"%@.idx", self.path];
            [self loadIndexWithPath:indexPath continuation:^(LinearIndex *index) {
                self.featureIndex = index;

                if (nil != index) {
                    // Compute a feature visibility window
                    double bpToByte = [self computeBasePairToByteDensity];
                    if (bpToByte > 0 && bpToByte < 500) {
                        self.visibilityWindowThreshold = (long long int) MAX(MINIMUM_VISIBILITY_WINDOW, MAX_FEATURE_FILE_BYTES * bpToByte);
                    }
                    else {
                        self.visibilityWindowThreshold = NSIntegerMax;
                    }
                }
                completion();
            }];
        }

        else {
            if (nil == self.featureIndex) {

                [self loadNonIndexedFeaturesForInterval:interval continuation:^() {
                    completion();
                }];

            } else {

                [self loadIndexedFeaturesForInterval:interval continuation:^() {
                    completion();
                }];
            }
        }
    }

}

/**
* Return an estimate of the average genomic density of the data file measured in base covered per byte length of file.
* The estimate is based on file offsets recorded in the index.  This parameter is useful for computing the feature
* visibility window.
*/
- (double)computeBasePairToByteDensity {

    long SA = 16;
    long AM = 0xFFFFFFFFFFFFL;

    int densityCount = 0;
    double densitySum = 0;
    for (NSString *chr in self.chromosomeNames) {
        NSString *genomeChr = [[GenomeManager sharedGenomeManager] chromosomeAliasForString:chr];
        if (genomeChr == nil) genomeChr = chr;
        NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:genomeChr];
        if (chromosomeExtent != nil) {

            long long int chromosomeLength = [chromosomeExtent length];
            if (chromosomeLength > 0) {

                FileRange *fileRange = [[self.featureIndex.chrIndices objectForKey:chr] getRangeOverlapping:0 end:(int) chromosomeLength];

                if (nil != fileRange && fileRange.byteCount > 0) {
                    densityCount++;
                    densitySum += ((double) chromosomeLength) / fileRange.byteCount;
                }
            }
        }
    }

    double avgDensity = densityCount == 0 ? 0 : densitySum / densityCount;
    return avgDensity;
}

- (void)loadIndexWithPath:(NSString *)indexPath continuation:(void (^)(LinearIndex *))continuation {

    [URLDataLoader loadDataWithPath:indexPath completion:^(HttpResponse *response) {

        if ([response statusCode] > 400) {
            continuation(nil);   // TODO -- could mean error, coul
        } else {
            continuation([IndexFactory indexFromData:response.receivedData pathExtension:[indexPath pathExtension]]);
        }
    }];
}


// Load all features in the file, cache them for later use, and return the interval requested
- (void)loadNonIndexedFeaturesForInterval:(FeatureInterval *)interval continuation:(LoadFeaturesCompletion)completion {

    [URLDataLoader loadDataWithPath:self.path completion:^(HttpResponse *response) {

        if ([response statusCode] > 400) {
            completion();               // TODO -- handle this error
        } else {

            NSError *error = nil;
            NSMutableArray *featureLists = [self decode:response.receivedData error:&error forQueryInterval:nil];

            for (FeatureList *featureList in featureLists) {
                [self.featureCache addFeatureList:featureList];
                [self updateStatsForFeatures:featureList.features];
            }
            self.featureCache.loadComplete = YES;

            completion();
        }

    }];


}


- (void)loadIndexedFeaturesForInterval:(FeatureInterval *)queryInterval
                          continuation:(LoadFeaturesCompletion)completion {

    NSString *fileChr = [self.chrTable objectForKey:queryInterval.chromosomeName];
    if (nil == fileChr) {
        fileChr = queryInterval.chromosomeName;
    }

    FileRange *fileRange = [[self.featureIndex.chrIndices objectForKey:fileChr] getRangeOverlapping:(int) queryInterval.start end:(int) queryInterval.end];

    [URLDataLoader loadDataWithPath:self.path forRange:fileRange completion:^(HttpResponse *response) {

        FeatureList *featureList;

        if ([response statusCode] > 400) {
            featureList = [FeatureList emptyFeatureListForInterval:queryInterval];

        } else {

            NSError *error = nil;
            NSMutableArray *featureListArray = [self decode:response.receivedData error:&error forQueryInterval:queryInterval];

            if (nil == featureListArray || [featureListArray count] == 0) {
                featureList = [FeatureList emptyFeatureListForInterval:queryInterval];
            }
            else {
                //Indexed => a single list
                featureList = [featureListArray objectAtIndex:0];
                [self updateStatsForFeatures:featureList.features];
            }
        }
        // For indexed sources we keep on feature list in memory.  This is a bit of a hack
        [self.featureCache clear];
        [self.featureCache addFeatureList:featureList];
        completion();
    }];

}


- (void)updateStatsForFeatures:(NSArray *)featureArray {

    if (nil == featureArray) {
        return;
    }

    if ([self.codec isKindOfClass:[WIGCodec class]]) {

        double sum = 0;
        double sumSquares = 0;
        double min = CGFLOAT_MAX;
        double max = -min;

        for (WIGFeature *feature in featureArray) {
            double score = feature.score;
            min = MIN(min, score);
            max = MAX(max, score);
            sum += score;
            sumSquares += score * score;
        }

        [self.bwTotalSummary updateStatsWithMin:min max:max sum:sum sumSquares:sumSquares count:featureArray.count];

    }

}

- (NSArray *)chromosomeNames {
    return self.featureIndex == nil ? self.featureCache.chromosomeNames : self.featureIndex.chromosomeNames;
}


- (NSMutableArray *)decode:(NSData *)data error:(NSError **)error forQueryInterval:(FeatureInterval *)queryInterval {

    NSData *srcData = data;
    if ([[self.path pathExtension] isEqualToString:@"gz"]) {
        srcData = [data gunzippedData];
    }

    BOOL pastHeader = NO;

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    LittleEndianByteBuffer *littleEndianByteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:srcData];

    NSString *lineRaw;
    while ((lineRaw = littleEndianByteBuffer.nextLine) != nil) {

        NSString *line = [ParsingUtils trimWhitespace:lineRaw];

        if (!pastHeader) {
            if ([line hasPrefix:@"track"]) {

                self.trackProperties = [ParsingUtils parseTrackLine:line];
                continue;

            } else if ([line hasPrefix:@"#"] || [line hasPrefix:@"browser"] || line.length == 0) {

                //ignore
                continue;
            }
        }

        NSString *chromosome = nil;
        NSError *lineError = nil;
        Feature *feature = [self.codec decodeLine:line chromosome:&chromosome error:&lineError];

        if (nil == feature) {

            if (lineError) {
                ALog(@"%@", [lineError localizedDescription]);
            }

            continue;
        } else {

            pastHeader = YES; // Headers not allowed after feature section starts
        }

        NSMutableArray *features = [dictionary objectForKey:chromosome];
        if (nil == features) {

            features = [NSMutableArray array];
            [dictionary setObject:features forKey:chromosome];
        }

        [features addObject:feature];

    } // while (...)

    // Set min/max in all feature lists.
    NSArray *chrs = dictionary.allKeys;
    NSMutableArray *featureLists = nil;

    for (NSString *chr in chrs) {

        NSArray *features = [dictionary objectForKey:chr];

        FeatureList *featureList = queryInterval == nil ?
                [FeatureList featureListForChromosome:chr features:features] :
                [FeatureList featureListForChromosome:chr start:queryInterval.start end:queryInterval.end features:features];

        if (nil == featureLists) {
            featureLists = [NSMutableArray array];
        }

        [featureLists addObject:featureList];
    }

    return featureLists;
}

+ (AsciiFeatureSource *)featureSourceForPath:(NSString *)path {
    return [[[AsciiFeatureSource alloc] initWithPath:path] autorelease];
}

- (NSString *)description {

    return [NSString stringWithFormat:@"%@ %@ path %@.", [self class], [self.codec class], self.path];
}

@end
