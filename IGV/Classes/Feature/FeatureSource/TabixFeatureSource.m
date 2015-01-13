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
// Created by jrobinso on 7/30/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "TabixFeatureSource.h"
#import "BlockCompressedInputStream.h"
#import "TabixIndex.h"
#import "FeatureInterval.h"
#import "Codec.h"
#import "Feature.h"
#import "FeatureCache.h"
#import "FeatureList.h"
#import "BEDCodec.h"
#import "GenomeManager.h"
#import "NSArray+Cytoband.h"

const int MAX_BIN = 37450;
const int TAD_LIDX_SHIFT = 14;

@interface TPair64 : NSObject
@end

@implementation TPair64 {
    long long _u;
    long long _v;
}

+ (TPair64 *)u:(long long)aU v:(long long)aV {
    return [[[self alloc] initForU:aU V:aV] autorelease];
}

- (TPair64 *)initForU:(long long)aU V:(long long)aV {
    self = [super init];
    if (nil != self) {
        _u = aU;
        _v = aV;
    }
    return self;
}

- (void)u:(long long)aU {
    _u = aU;
}

- (void)v:(long long)aV {
    _v = aV;
}

- (long long)u {
    return _u;
}

- (long long)v {
    return _v;
}

- (NSComparisonResult)compare:(TPair64 *)p {
    return _u == p.u ? 0 : ((_u < p.u) ^ (_u < 0) ^ (p.u < 0)) ? -1 : 1; // unsigned 64-bit comparison
}

//public int compareTo(final TPair64 p) {
//    return u == p.u ? 0 : ((u < p.u) ^ (u < 0) ^ (p.u < 0)) ? -1 : 1; // unsigned 64-bit comparison
//}
@end

@interface TabixFeatureSource ()
@property(nonatomic, retain) Codec *codec;
@property(nonatomic, retain) BlockCompressedInputStream *bis;
@property(nonatomic, retain) NSMutableDictionary *indexDictionary;
@property(nonatomic, retain) NSMutableArray *sequenceNames;
- (void)readIndex;
@end

@implementation TabixFeatureSource {
    int _preset;
    int _sc;
    int _bc;
    int _ec;
    int _meta;
    int _skip;
}

@synthesize codec = _codec;
@synthesize bis = _bis;
@synthesize indexDictionary = _indexDictionary;
@synthesize sequenceNames = _sequenceNames;
@synthesize filePath = _path;

- (void)dealloc {

    self.sequenceNames = nil;
    self.indexDictionary = nil;
    self.bis = nil;
    self.codec = nil;

    [super dealloc];
}

- (id)initWithFilePath:(NSString *)filePath {

    self = [super init];

    if (self) {

        self.filePath = filePath;
        self.bis = [BlockCompressedInputStream streamForURL:filePath];

        // TODO -- determine codec from aPath
        self.codec = [[[BEDCodec alloc] init] autorelease];

        [self readIndex];

        double bpToByte = [self computeBasePairToByteDensity];
        if (bpToByte > 0 && bpToByte <500) {
            self.visibilityWindowThreshold = (long long int) MAX(MINIMUM_VISIBILITY_WINDOW, MAX_FEATURE_FILE_BYTES * bpToByte);
        }
        else {
            self.visibilityWindowThreshold = NSIntegerMax;
        }
    }

    return self;
}

- (void)loadFeaturesForInterval:(FeatureInterval *)interval completion:(LoadFeaturesCompletion)completion {


    //  dispatch_async([UIApplication sharedIGVAppDelegate].featureSourceQueue, ^{

    [self decodeFeaturesForFeatureInterval:interval];

    completion();
    //  });
}

- (void)decodeFeaturesForFeatureInterval:(FeatureInterval *)featureInterval {

    NSMutableArray *features = [NSMutableArray array];

    NSString *fileChr = [self.chrTable objectForKey:featureInterval.chromosomeName];
    if (fileChr == nil) {
        fileChr = featureInterval.chromosomeName;
    }

    NSArray *chunks = [self chunksForChr:fileChr start:(int) featureInterval.start end:(int) featureInterval.end];

    if (nil == chunks || 0 == [chunks count]) {


        NSLog(@"ERROR nil == chunks || 0 == [chunks count]");
        [self.featureCache addFeatureList:[FeatureList emptyFeatureListForInterval:featureInterval]];
        return;
    }

    for (NSUInteger i = 0; i < [chunks count]; i++) {

        TPair64 *chunk = [chunks objectAtIndex:i];
        [self.bis seekToPosition:chunk.u];

        NSUInteger lineCount = 0;
        NSString *line;
        while ((line = [self.bis nextLine]) != nil) {

            ++lineCount;

            NSString *chromosome = NULL;
            NSError *lineError = nil;
            Feature *feature = [self.codec decodeLine:line chromosome:&chromosome error:&lineError];

            if (nil == feature) {

                if (lineError) {
                    NSLog(@"Chunks %d. Chunk %d. LineCount %d. Line %@. Feature is NIL. Error: %@", [chunks count], i, lineCount, line, [lineError localizedDescription]);
                }

                continue;
            }

            if (feature.end < featureInterval.start) {
                continue;
            }

            if (![chromosome isEqualToString:featureInterval.chromosomeName] || feature.start > featureInterval.end) {
                break;
            }

            [features addObject:feature];

        }
    }


    // For indexed sources we keep on feature list in memory.  This is a bit of a hack
    [self.featureCache clear];

    FeatureList *featureList = (0 == [features count]) ?
            [FeatureList emptyFeatureListForChromosome:featureInterval.chromosomeName] :
            [FeatureList featureListForChromosome:featureInterval.chromosomeName start:featureInterval.start end:featureInterval.end features:features];
    [self.featureCache addFeatureList:featureList];

}

- (NSArray *)chromosomeNames {
    return self.sequenceNames;
}

/**
* Return an estimate of the averagegenomic density of the data file measured in base covered per byte length of file.
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
                NSArray *chunks = [self chunksForChr:chr start:0 end:(int) chromosomeLength];
                if ([chunks count] > 0) {
                    TPair64 *first = [chunks objectAtIndex:0];
                    TPair64 *last = [chunks objectAtIndex:([chunks count] - 1)];
                    long long int compressedOffset1 = (first.u >> SA) & AM;
                    long long int compressedOffset2 = (last.v >> SA) & AM;
                    long long int bytes = compressedOffset2 - compressedOffset1;
                    densityCount++;
                    densitySum += ((double) chromosomeLength) / bytes;
                }
            }
        }
    }
    // The file is gzipped, so its actually a bit denser than compute above in uncompressed bytes.  We'll assume
    // 80% compression =>  divide average by 5
    return densityCount == 0 ? 0 : (densitySum / densityCount) / 5;
}

/**
* Read the Tabix index from a file
*
* @param fp File pointer
*/
- (void)readIndex {

    NSString *tabixPath = [self.filePath stringByAppendingString:@".tbi"];

    BlockCompressedInputStream *tabixBIS = [[BlockCompressedInputStream streamForURL:tabixPath] retain];

    // dat - get rid of warning nag
//    int magicNumber = [tabixBIS nextInt];  // read "TBI\1"
    (void) [tabixBIS nextInt];  // read "TBI\1"

    int sequenceCount = [tabixBIS nextInt];

    self.sequenceNames = [NSMutableArray arrayWithCapacity:(NSUInteger) sequenceCount];

    _preset = [tabixBIS nextInt];
    _sc = [tabixBIS nextInt];
    _bc = [tabixBIS nextInt];
    _ec = [tabixBIS nextInt];
    _meta = [tabixBIS nextInt];
    _skip = [tabixBIS nextInt];

    // read sequence dictionary
    [tabixBIS nextInt]; // sequence buffer size, not used

    for (int k = 0; k < sequenceCount; k++) {
        NSString *sequenceName = [tabixBIS nextString];
        [self.sequenceNames addObject:sequenceName];

    }


    self.indexDictionary = [NSMutableDictionary dictionaryWithCapacity:(NSUInteger) sequenceCount];


    for (NSUInteger i = 0; i < sequenceCount; ++i) {

        NSString *sequenceName = [self.sequenceNames objectAtIndex:i];

        // the binning index
        int n_bin = [tabixBIS nextInt];

        TabixIndex *idx = [[[TabixIndex alloc] init] autorelease];
        [self.indexDictionary setValue:idx forKey:sequenceName];


        for (int j = 0; j < n_bin; ++j) {

            int bin = [tabixBIS nextInt];
            int chunkCount = [tabixBIS nextInt];

            NSMutableArray *chunks = [NSMutableArray arrayWithCapacity:(NSUInteger) chunkCount];

            for (int k = 0; k < chunkCount; ++k) {
                long long u = [tabixBIS nextLong];
                long long v = [tabixBIS nextLong];
                TPair64 *chunk = [TPair64 u:u v:v];
                [chunks addObject:chunk];
            }
            // mIndex[i].b.put(bin, chunks);
            [idx putChunks:chunks forBin:bin];
        }

        // the linear index
        int linearIndexSize = [tabixBIS nextInt];
        long long *liArray = malloc((size_t) (linearIndexSize * sizeof(long long)));
        for (int k = 0; k < linearIndexSize; k++) {
            liArray[k] = [tabixBIS nextLong];
        }

        [idx linearIndex:liArray length:linearIndexSize];
    }

    [tabixBIS release];

}

- (NSMutableArray *)chunksForChr:(NSString *)chrName
                           start:
                                   (int)beg
                             end:
                                     (int)end {


    long long min_off;
    TabixIndex *idx = [self.indexDictionary objectForKey:chrName];


    int bins[MAX_BIN];
    int i;
    int l;
    int n_off;

    int n_bins = [self reg2binsForBeg:beg end:end bins:bins];

    long long *linearIndex = [idx linearIndex];
    int linearIndexLength = [idx linearIndexLength];
    if (linearIndexLength > 0) {
        min_off = (beg >> TAD_LIDX_SHIFT >= linearIndexLength) ? linearIndex[linearIndexLength - 1] : linearIndex[beg >> TAD_LIDX_SHIFT];
    }
    else {
        min_off = 0;
    }


    for (i = n_off = 0; i < n_bins; ++i) {
        int bin = bins[i];
        NSMutableArray *chunks = [idx chunksForBin:bin];
        if (chunks != nil) {
            n_off += chunks.count;
        }
    }

    if (n_off == 0) return nil;

    NSMutableArray *off = [NSMutableArray arrayWithCapacity:n_off];

    for (i = n_off = 0; i < n_bins; ++i) {
        int bin = bins[i];
        NSMutableArray *chunks = [idx chunksForBin:bin];
        if (chunks != nil) {
            for (int j = 0; j < chunks.count; ++j) {

                TPair64 *chunk = [chunks objectAtIndex:j];

                if ([self less64Left:min_off right:chunk.v]) {
                    [off addObject:[TPair64 u:chunk.u v:chunk.v]];
                    n_off++;
                }
            }
        }
    }
    if (n_off == 0) return nil;

    [off sortUsingSelector:@selector(compare:)];

    // resolve completely contained adjacent alignmentBlocks
    for (i = 1, l = 0; i < n_off; ++i) {

        TPair64 *offl = [off objectAtIndex:l];
        TPair64 *offi = [off objectAtIndex:i];

        if ([self less64Left:offl.v right:offi.v]) {
            ++l;
            offl = [off objectAtIndex:l];
            [offl u:offi.u];
            [offl v:offi.v];
        }
    }

    n_off = l + 1;

    // resolve overlaps between adjacent alignmentBlocks; this may happen due to the merge in indexing
    for (i = 1; i < n_off; ++i) {
        TPair64 *offi_1 = [off objectAtIndex:i - 1];
        TPair64 *offi = [off objectAtIndex:i];
        if (![self less64Left:offi_1.v right:offi.u]) {
            [offi_1 v:offi.u];
        }
    }

    // merge adjacent alignmentBlocks
    for (i = 1, l = 0; i < n_off; ++i) {

        TPair64 *offl = [off objectAtIndex:l];
        TPair64 *offi = [off objectAtIndex:i];

        if (offl.v >> 16 == offi.u >> 16) {
            [offl v:offi.v];
        }
        else {
            ++l;
            offl = [off objectAtIndex:l];
            [offl u:offi.u];
            [offl v:offi.v];
        }
    }
    n_off = l + 1;

    // return
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:n_off];
    for (i = 0; i < n_off; ++i) {
        TPair64 *offi = [off objectAtIndex:i];
        [ret addObject:offi];
    }
    return ret;
}

- (int)reg2binsForBeg:(int)beg
                  end:
                          (int)end
                 bins:
                         (int *)list {
    int i = 0, k;
    if (beg >= end) return 0;
    if (end >= 1 << 29) end = 1 << 29;
    --end;
    list[i++] = 0;
    for (k = 1 + (beg >> 26); k <= 1 + (end >> 26); ++k) list[i++] = k;
    for (k = 9 + (beg >> 23); k <= 9 + (end >> 23); ++k) list[i++] = k;
    for (k = 73 + (beg >> 20); k <= 73 + (end >> 20); ++k) list[i++] = k;
    for (k = 585 + (beg >> 17); k <= 585 + (end >> 17); ++k) list[i++] = k;
    for (k = 4681 + (beg >> 14); k <= 4681 + (end >> 14); ++k) list[i++] = k;
    return i;
}

- (BOOL)less64Left:(long long)u
             right:
                     (long long)v { // unsigned 64-bit comparison
    return (u < v) ^ (u < 0) ^ (v < 0);
}

- (NSString *)description {

    return [NSString stringWithFormat:@"%@ %@ path %@.", [self class], [self.codec class], self.filePath];
}

@end