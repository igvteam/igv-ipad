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
// Created by turner on 12/9/13.
//

#import "SEGFeatureSource.h"
#import "LittleEndianByteBuffer.h"
#import "ParsingUtils.h"
#import "Feature.h"
#import "Codec.h"
#import "NSData+GZIP.h"
#import "SEGCodec.h"
#import "SEGFeature.h"
#import "Logging.h"
#import "IGVContext.h"
#import "FeatureInterval.h"
#import "TrackView.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "NSArray+Cytoband.h"

@interface SEGFeatureSource ()
@property(nonatomic, retain) SEGCodec *codec;
@end

@implementation SEGFeatureSource

@synthesize samples = _samples;
@synthesize data = _data;
@synthesize sampleNames;
@synthesize reverseSortOrder = _reverseSortOrder;

- (void)dealloc {

    self.samples = nil;
    self.data = nil;
    self.sampleNames = nil;
    self.codec = nil;
    self.path = nil;
    [super dealloc];
}

- (id)initWithPath:(NSString *)path {

    self = [super init];

    if (nil != self) {

        self.path = path;
        self.codec = [[[SEGCodec alloc] init] autorelease];
        self.reverseSortOrder = YES;
    }

    return self;
}

// Sort sample rows based on value at the genomic location.
// NOTE:  Its implicitly assumed here that the chromosomeName is == the chromosomeName of the data we have stored
- (void)sortSamplesWithLocation:(long long int)location {

    NSArray *values = self.samples.allValues;
    if ([values count] == 0) return; // Nothing to sort

    NSComparator sampleNameComparator = ^(NSString *aSampleName, NSString *bSampleName) {

        NSDictionary *sampleRowDict = [values objectAtIndex:0];

        NSArray *aSampleRow = [sampleRowDict objectForKey:aSampleName];
        NSArray *bSampleRow = [sampleRowDict objectForKey:bSampleName];

        double sumA = 0;
        int countA = 0;
        double width = 36 / [IGVContext sharedIGVContext].pointsPerBase;
        if (nil != aSampleRow) {
            for (SEGFeature *feature in aSampleRow) {
                if ([feature hitTestWithLocation:location width:width]) {
                    sumA += feature.value;
                    countA++;
                }
            }
        }

        double sumB = 0;
        int countB = 0;
        if (nil != bSampleRow) {
            for (SEGFeature *feature in bSampleRow) {
                if ([feature hitTestWithLocation:location width:width]) {
                    sumB += feature.value;
                    countB++;
                }
            }
        }

        CGFloat nullValue = self.reverseSortOrder ? -CGFLOAT_MAX : CGFLOAT_MAX;
        CGFloat aValue = countA > 0 ? sumA / countA : nullValue;
        CGFloat bValue = countB > 0 ? sumB / countB : nullValue;

        if (aValue == bValue) {
            return NSOrderedSame;
        } else if (aValue > bValue) {
            return self.reverseSortOrder ? NSOrderedDescending : NSOrderedAscending;
        } else {
            return self.reverseSortOrder ? NSOrderedAscending : NSOrderedDescending;
        }

    };

    [self.sampleNames sortUsingComparator:sampleNameComparator];

    self.reverseSortOrder = !self.reverseSortOrder;
}

- (void)loadFeaturesForInterval:(FeatureInterval *)featureInterval completion:(LoadFeaturesCompletion)completion {

    if (nil == self.data) {

        // Need to get data, then try again
        [URLDataLoader loadDataWithPath:self.path completion:^(HttpResponse *httpResponse) {

            // TODO -- check for error in httpResponse.
            if ([httpResponse statusCode] > 400) {
                ALog(@"DANGER: http status code %d. Bailing", [httpResponse statusCode]);
                return;
            }

            // cache data
            self.data = httpResponse.receivedData;
            if ([[self.path pathExtension] isEqualToString:@"gz"]) {
                self.data = [httpResponse.receivedData gunzippedData];
            }
            [self loadFeaturesForInterval:featureInterval completion:completion];
        }];

    } else {

        // decode
        self.samples = [self decode:self.data chromosome:featureInterval.chromosomeName];

        completion();
    }

}

// Return value is a dictionary of dictionaries of sampleRows.  A sampleRow is basically an array of features.
// chromosomeName -> sampleName -> sampleRow.
// Note, in the current implementation the outermost dictionary will only have a single entry (1 chromosomeName).

- (NSDictionary *)decode:(NSData *)data chromosome:(NSString *)queryChromosome {

    bool initializeSampleName = NO;
    NSMutableOrderedSet *sampleNamesReadOrder = nil;
    if (nil == self.sampleNames) {
        // Do this only once, for the whole file
        sampleNamesReadOrder = [NSMutableOrderedSet orderedSet];
        initializeSampleName = YES;
    }


    NSMutableDictionary *sampleDictionary = [NSMutableDictionary dictionary];

    SEGCodec *segCodec = self.codec;

    BOOL pastHeader = NO;

    LittleEndianByteBuffer *littleEndianByteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    NSString *rawLine;

    // Header row, currently we don't use it
    NSString *header = [littleEndianByteBuffer nextLine];

    while ((rawLine = [littleEndianByteBuffer nextLine]) != nil) {

        NSString *line = [ParsingUtils trimWhitespace:rawLine];

        NSString *chromosome = nil;
        NSString *sampleName = nil;
        NSError *lineError = nil;
        SEGFeature *segFeature = (SEGFeature *) [segCodec decodeLine:line sampleName:&sampleName chromosome:&chromosome error:&lineError];

        if (nil == segFeature) {

            ALog(@"%@", [lineError localizedDescription]);
            continue;
        }

        if (initializeSampleName) {
            if (sampleNamesReadOrder) [sampleNamesReadOrder addObject:sampleName];
        }

        // We only keep records samples corresponding to the current chromosomeName due to memory constaints
        if ([chromosome isEqualToString:queryChromosome]) {

            NSMutableArray *sampleRow = [sampleDictionary objectForKey:sampleName];
            if (nil == sampleRow) {
                sampleRow = [NSMutableArray array];
                [sampleDictionary setObject:sampleRow forKey:sampleName];
            }

            [sampleRow addObject:segFeature];
        }

    }

    if (initializeSampleName) {
        if (sampleNamesReadOrder) self.sampleNames = [NSMutableArray arrayWithArray:[sampleNamesReadOrder array]];
    }

    return [NSDictionary dictionaryWithObject:sampleDictionary forKey:queryChromosome];
}

- (id)featuresForFeatureInterval:(FeatureInterval *)featureInterval {

    if (nil == self.samples) {
        return nil;
    }

    return [self.samples objectForKey:featureInterval.chromosomeName];
}

+ (SEGFeatureSource *)featureSourceForPath:(NSString *)path {
    return [[[SEGFeatureSource alloc] initWithPath:path] autorelease];
}


@end