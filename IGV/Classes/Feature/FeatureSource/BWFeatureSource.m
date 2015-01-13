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
// Created by James Robinson on 1/16/14.
//

#import "BWFeatureSource.h"
#import "FeatureInterval.h"
#import "BWReader.h"
#import "IGVContext.h"
#import "BWZoomLevelHeader.h"
#import "LMResource.h"
#import "RPTree.h"
#import "NSData+GZIP.h"
#import "LittleEndianByteBuffer.h"
#import "ParsingUtils.h"
#import "Logging.h"
#import "BPTree.h"
#import "UIApplication+IGVApplication.h"
#import "IGVAppDelegate.h"
#import "FeatureList.h"
#import "FeatureList.h"
#import "WIGFeature.h"
#import "FeatureCache.h"
#import "BWHeader.h"
#import "BWTotalSummary.h"


int const ZOOMDATA_RECORD_SIZE = 32;

@interface BWFeatureSource ()
@property(nonatomic, retain) FeatureList *currentFeatureList;
@end

@implementation BWFeatureSource

- (void)dealloc {
    self.reader = nil;
    self.currentFeatureList = nil;
    [super dealloc];
}

- (id)initWithFilePath:(NSString *)filePath {

    self = [super init];

    if (nil != self) {

        // self.color = resource.color;
        self.filePath = filePath;
        self.reader = [[[BWReader alloc] initWithPath:self.filePath] autorelease];
        self.currentFeatureList = nil;

    }

    return self;

}


- (NSArray *)chromosomeNames {

    if (nil == self.reader.header) {
        [self.reader loadHeader];
    }

    return nil == self.reader.chromTree ? nil : self.reader.chromTree.dictionary.allKeys;

}

- (id)featuresForFeatureInterval:(FeatureInterval *)featureInterval {

    if (nil == self.currentFeatureList) return nil;

    else {
        double bpPerPixel = 1.0 / [[IGVContext sharedIGVContext] pointsPerBase];
        BWZoomLevelHeader *zoomLevelHeader = [self zoomLevelForScale:bpPerPixel];
        int zoomIndex = (nil == zoomLevelHeader) ? NSIntegerMax : zoomLevelHeader.index;

        if ([self.currentFeatureList.featureInterval containsChromosomeName:featureInterval.chromosomeName start:featureInterval.start
                                                                        end:featureInterval.end zoomLevel:zoomIndex]) {

            FeatureList *featureList = self.currentFeatureList;

            // Override min & max with computed stats
            BWTotalSummary *summary = self.reader.totalSummary;
            double range = 2 * summary.stddev;

            if (summary.minVal >= 0) {
                // All (+) values
                featureList.minScore = 0;
                featureList.maxScore = summary.mean + range;
            }
            else if (summary.maxVal <= 0) {
                // All (-) values
                featureList.maxScore = 0;
                featureList.minScore = summary.mean - range;
            }
            else {
                // Both + and - values.  // TODO -- we don't render this correctly, need a line through 0
                featureList.minScore = range;
                featureList.maxScore = range;
            }

            return featureList;
        }
        else {
            return nil;
        }

    }


}


- (void)loadFeaturesForInterval:(FeatureInterval *)featureInterval completion:(LoadFeaturesCompletion)completion {


    dispatch_async([UIApplication sharedIGVAppDelegate].featureSourceQueue, ^{

        // if (self.minValue == NSIntegerMax) {
        //     [self initMinMax];   // <= takes too long.
        // }

        // Use the chromosomeName name as represented in this source, which can differ from the name used in the genome def
        double bpPerPixel = 1.0 / [[IGVContext sharedIGVContext] pointsPerBase];
        FeatureList *featureList = [self loadFeatureList:featureInterval resolution:bpPerPixel];

        self.currentFeatureList = featureList;

        // Override data range for now
        BWTotalSummary *totalSummary = self.reader.totalSummary;
        featureList.minScore = 0; //self.minValue;
        featureList.maxScore = totalSummary.mean + 2 * totalSummary.stddev;

        completion();
    });

}

- (FeatureList *)loadFeatureList:(FeatureInterval *)featureInterval resolution:(double)bpPerPixel {

    NSString *fileChr = [self.chrTable objectForKey:featureInterval.chromosomeName];
    if (nil == fileChr) {
        fileChr = featureInterval.chromosomeName;
    }
    long long int intervalStart = featureInterval.start;
    long long int intervalEnd = featureInterval.end;


    if (nil == self.reader.header) {
        // Load header and try again
        [self.reader loadHeader];
    }

    int chrIdx = [self.reader idxForChr:fileChr];

    FeatureList *featureList;
    if (chrIdx < 0) {
        featureList = [FeatureList emptyFeatureListForChromosome:featureInterval.chromosomeName];
    }

    else {

        // Select a biwig "zoom level" appropriate for the current resolution
        BWZoomLevelHeader *zoomLevelHeader = [self zoomLevelForScale:bpPerPixel];

        // Check resolution against requested resolution.  If too course use "raw" wig data.

        BOOL useZoomData = zoomLevelHeader != nil;
        int bwZoomLevel = useZoomData ? zoomLevelHeader.index : NSIntegerMax;
        long long int treeOffset = useZoomData ? zoomLevelHeader.indexOffset : self.reader.header.fullIndexOffset;

        RPTree *rpTree = [self.reader rpTreeAtOffset:treeOffset];
        NSMutableArray *leafItems = [NSMutableArray array];
        [rpTree findLeafItemsOverlappingChr:chrIdx startBase:intervalStart endBase:intervalEnd items:leafItems];

        if (leafItems.count == 0) {
            featureList = [FeatureList emptyFeatureListForInterval:featureInterval];
        }
        else {
            // Sort items by genomic position
            [leafItems sortUsingComparator:^NSComparisonResult(RPTItem *d1, RPTItem *d2) {
                if (d1.startBase < d2.startBase)
                    return NSOrderedAscending;
                else if (d1.startBase > d2.startBase)
                    return NSOrderedDescending;
                else return NSOrderedSame;
            }];

            // Grab data for all items.
            int s = ((RPTLeafItem *) leafItems.firstObject).dataOffset;
            RPTLeafItem *lastItem = (RPTLeafItem *) leafItems.lastObject;
            int e = lastItem.dataOffset + lastItem.dataSize;
            int byteCount = e - s;
            NSData *buffer = [self.reader loadDataAtOffset:s size:byteCount];

            // Loop through items, decompress and decode

            NSError *error = nil;
            NSMutableArray *allFeatures = [NSMutableArray array];
            for (RPTLeafItem *item in leafItems) {

                // Offset into data buffer
                int bufferOffset = item.dataOffset - s;
                NSRange range = NSMakeRange(bufferOffset, item.dataSize);



//                NSData *data = [[[NSData alloc] initWithGzippedData:[buffer subdataWithRange:range]] autorelease];
                NSData *data = [[buffer subdataWithRange:range] gunzippedData];

                NSMutableArray *featureArray = useZoomData ?
                        [self decodeZoomData:data chrIdx:chrIdx start:intervalStart end:intervalEnd error:&error] :
                        [self decodeWigData:data chrIdx:chrIdx start:intervalStart end:intervalEnd error:&error];

                // WIG features never overlap, so we can potentially expand the query interval if we have grabbed
                // features outside
                for (WIGFeature *feature in featureArray) {
                    intervalStart = MIN(intervalStart, feature.start);
                    intervalEnd = MAX(intervalEnd, feature.end);
                    [allFeatures addObject:feature];
                }
            }


            FeatureInterval *asQueriedInterval = [FeatureInterval intervalWithChromosomeName:featureInterval.chromosomeName start:intervalStart end:intervalEnd zoomLevel:bwZoomLevel];
            featureList = [FeatureList featureListForFeatureInterval:asQueriedInterval features:allFeatures];
        }

    }
    return featureList;
}


- (NSMutableArray *)decodeZoomData:(NSData *)data chrIdx:(int)chrIdx start:(int)start end:(int)end error:(NSError **)error {

    LittleEndianByteBuffer *buffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    int itemCount = buffer.available / ZOOMDATA_RECORD_SIZE;
    NSMutableArray *featureArray = [NSMutableArray arrayWithCapacity:(NSUInteger)itemCount];

    while (buffer.available >= ZOOMDATA_RECORD_SIZE) {
        int chromId = [buffer nextInt];
        int chromStart = [buffer nextInt];
        int chromEnd = [buffer nextInt];

        if (chromId > chrIdx || (chromId == chrIdx && chromStart > end)) break;

        int validCount = [buffer nextInt];
        float minVal = [buffer nextFloat];
        float maxVal = [buffer nextFloat];
        float sumData = [buffer nextFloat];
        float sumSquares = [buffer nextFloat];

        float mean = sumData / validCount;

        if (chromId == chrIdx && chromEnd > start) {
            WIGFeature *feature = [[[WIGFeature alloc] initWithStart:chromStart end:chromEnd score:mean] autorelease];
            [featureArray addObject:feature];
        }

    }
    return featureArray;

}


- (NSMutableArray *)decodeWigData:(NSData *)data chrIdx:(int)chrIdx start:(int)start end:(int)end error:(NSError **)error {

    LittleEndianByteBuffer *buffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    int chromId = [buffer nextInt];
    int chromStart = [buffer nextInt];
    int chromEnd = [buffer nextInt];
    int itemStep = [buffer nextInt];
    int itemSpan = [buffer nextInt];
    u_char type = [buffer nextByte];
    u_char reserved = [buffer nextByte];
    short itemCount = [buffer nextShort];
    NSMutableArray *featureArray = [NSMutableArray arrayWithCapacity:(NSUInteger)itemCount];

    if (chromId == chrIdx) {

        while (itemCount-- > 0) {

            WIGFeature *feature = nil;
            float value;

            switch (type) {

                case 1:
                    chromStart = [buffer nextInt];
                    chromEnd = [buffer nextInt];
                    value = [buffer nextFloat];
                    chromEnd = chromStart + itemSpan;
                    feature = [[[WIGFeature alloc] initWithStart:chromStart end:chromEnd score:value] autorelease];

                    break;

                case 2:

                    chromStart = [buffer nextInt];
                    value = [buffer nextFloat];
                    chromEnd = chromStart + itemSpan;
                    feature = [[[WIGFeature alloc] initWithStart:chromStart end:chromEnd score:value] autorelease];

                    break;

                case 3:  // Fixed step
                    value = [buffer nextFloat];
                    chromEnd = chromStart + itemSpan;
                    feature = [[[WIGFeature alloc] initWithStart:chromStart end:chromEnd score:value] autorelease];

                    chromStart += itemStep;
                    break;

                default: {
                    // nuthin
                }

            }

            if (feature) {
                [featureArray addObject:feature];
            }
        }

    }

    return featureArray;
}


// Note: This is exposed in the public interface for unit testing only
- (BWZoomLevelHeader *)zoomLevelForScale:(double)bpPerPixel {

    NSMutableArray *zoomLevelHeaders = self.reader.zoomLevelHeaders;

    BWZoomLevelHeader *level = nil;
    for (BWZoomLevelHeader *zl in zoomLevelHeaders) {

        if (zl.reductionLevel > bpPerPixel) {
            level = zl;
            break;
        }
    }
    if (nil == level) zoomLevelHeaders.lastObject;

    BOOL useZoomData = (level.reductionLevel < 4 * bpPerPixel);

    return useZoomData ? level : nil;

}


@end