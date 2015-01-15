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
//  BAMReader.m
//
//  Represents an alignment data source backed by a "bam" file.  Basically a bridge between Objective-c and samtools.
//
//  Created by James Robinson on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BAMReader.h"
#import "Alignment.h"
#import "Logging.h"
#import "IGVHelpful.h"
#import "AlignmentResults.h"
#import "NSUserDefaults+LocusFileURL.h"
#import "Coverage.h"
#import "LMResource.h"
#import "RefSeqTrackController.h"
#import "GenomeManager.h"
#import "FeatureInterval.h"
#import "UIApplication+IGVApplication.h"
#import "RefSeqTrackView.h"
#import "LMResource.h"

@interface BAMReader ()
@property(nonatomic, retain) NSString *filePath;
@property(nonatomic, copy) NSString *indexPath;
@property(nonatomic, retain) NSLock *readLock;
+ (NSInteger)alignmentSamplingWindowSize;
+ (NSInteger)alignmentSamplingWindowDepth;
- (BOOL)fetchIndexFileWithError:(NSError **)error;
@end

@implementation BAMReader {
    samfile_t *_samFile;
    bam_index_t *_index;
}

@synthesize chromosomeNames=_chromosomeNames;
@synthesize filePath = _filePath;
@synthesize chrLookupTable=_chrLookupTable;
@synthesize readLock;

void bam_init_header_hash(bam_header_t *header);

- (void)dealloc {

    if (_index) {
        bam_index_destroy(_index);
    }

    if (_samFile) {
        samclose(_samFile);
    }

    self.chromosomeNames = nil;

    self.filePath = nil;
    self.indexPath = nil;

    self.chrLookupTable = nil;
    self.readLock = nil;

    [super dealloc];
}

- (id)initWithResource:(LMResource *)resource {

    self = [super init];

    if (nil != self) {

        self.filePath = resource.filePath;
        self.indexPath = resource.indexPath;

        _index = 0;
        _samFile = 0;
    }

    return self;

}

- (id)initWithPath:(NSString *)path {

    self = [super init];
    
    if (nil != self) {

        self.filePath = path;
        _index = 0;
        _samFile = 0;
    }

    return self;
}

+(NSInteger)alignmentSamplingWindowSize {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAlignmentWindowSizeKey];
}

+(NSInteger)alignmentSamplingWindowDepth {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAlignmentWindowDepthKey];
}

- (NSLock *)readLock {

    if (nil == readLock) {

        self.readLock = [[[NSLock alloc] init] autorelease];
    }

    return readLock;
}

- (NSMutableArray *)chromosomeNames {

    if (nil == _chromosomeNames) {

        self.chromosomeNames = [NSMutableArray array];
    }

    return _chromosomeNames;
}

- (NSMutableDictionary *)chrLookupTable {

    if (nil == _chrLookupTable) {

        self.chrLookupTable = [NSMutableDictionary dictionary];
    }

    return _chrLookupTable;
}

- (AlignmentResults *)fetchAlignmentsWithFeatureInterval:(FeatureInterval *)featureInterval error:(NSError **)error {

    [self.readLock lock];

    BOOL success = NO;
    if (0 == _index) {
        success = [self fetchIndexFileWithError:error];
    }

    if ([IGVHelpful errorDetected:*error]) {

        ALog(@"%@", [*error localizedDescription]);

        [self.readLock unlock];
        return nil;
    }

    NSString *bamChrName = [self.chrLookupTable objectForKey:featureInterval.chromosomeName];
    if (nil == bamChrName) {
        bamChrName = featureInterval.chromosomeName;
    }

    int tid = bam_get_tid(_samFile->header, [bamChrName UTF8String]);
    if (tid < 0) {
        // Not present in this file
        [self.readLock unlock];
        return nil;
    }


    bam1_t *b = bam_init1();
    bam_iter_t iter = bam_iter_query(_index, tid, (int) featureInterval.start, (int) featureInterval.end);

    long long int windowEnd = -1;
    int alignmentsInBucketCount = 0;
    int downsampledCount = 0;
    int sampleWindowStartIndex = 0;
    BOOL wasDownsampled = NO;

//    Coverage *coverage = [[[Coverage alloc] init] autorelease];
    Coverage *coverage = [[[Coverage alloc] initWithRefSeqFeatureSource:[UIApplication sharedRootContentController].refSeqTrack.featureSource] autorelease];
    NSMutableArray *alignments = nil;
    while (bam_iter_read(_samFile->x.bam, iter, b) >= 0) {

        Alignment *alignment = [[[Alignment alloc] initWithStructure:b] autorelease];

        [coverage accumulateCoverageWithAlignment:alignment];

        if (nil == alignments) {
            alignments = [NSMutableArray array];
        }

        if (alignment.start > windowEnd) {

            // Start next window
            sampleWindowStartIndex = [alignments count];
            windowEnd = alignment.start + [BAMReader alignmentSamplingWindowSize];
            alignmentsInBucketCount = 0;
            downsampledCount = 0;
        }

        if (alignmentsInBucketCount > [BAMReader alignmentSamplingWindowDepth]) {

            // We've added the current allocation for this window.  Conditionally replace one of the existing elements
            double samplingProbability = ((double) [BAMReader alignmentSamplingWindowDepth]) / ([BAMReader alignmentSamplingWindowDepth] + downsampledCount + 1);

            int random = arc4random_uniform(1000);
            if ((samplingProbability * 1000) > random) {

                NSUInteger index = (NSUInteger) sampleWindowStartIndex + (NSUInteger) arc4random_uniform((u_int32_t) [BAMReader alignmentSamplingWindowDepth]);

                if (index >= [alignments count]) {

                    // This should never happen, log for debugging
                    ALog("Error in alignment sampling.  Replacement idx (%d) >= alignments array size (%d)", index, [alignments count]);
                } else {

                    [alignments replaceObjectAtIndex:index withObject:alignment];
                    wasDownsampled = YES;
                }
            }

            downsampledCount++;

        } else {

            [alignments addObject:alignment];
            alignmentsInBucketCount++;
        }
    }

    if (wasDownsampled) {

        [alignments sortUsingComparator:(NSComparator)^(Alignment *aa, Alignment *bb) {
            if (aa.start == bb.start) return NSOrderedSame;
            return (aa.start < bb.start) ? NSOrderedAscending : NSOrderedDescending;
        }];

    }

    bam_iter_destroy(iter);
    bam_destroy1(b);
    [self.readLock unlock];

    return [[[AlignmentResults alloc] initWithAlignments:alignments coverage:coverage] autorelease];
}

- (BOOL)fetchIndexFileWithError:(NSError **)error {

    _samFile = samopen([self.filePath UTF8String], "rb", 0);

    if (nil == _samFile) {

        *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"ERROR: samopen(%@) returned nil", self.filePath]];

        ALog(@"nil == _samFile. %@", [*error localizedDescription]);
        return NO;
    }

    if (nil == _samFile->header) {

        *error = [IGVHelpful errorWithDetailString:@"ERROR: _samFile->header == nil"];
        ALog(@"nil == _samFile->header. %@", [*error localizedDescription]);
        return NO;
    }

    bam_init_header_hash(_samFile->header);
    bam_header_t *header = _samFile->header;

    for (int i = 0; i < header->n_targets; ++i) {

        [self.chromosomeNames addObject:[NSString stringWithUTF8String:header->target_name[i]]];

        NSString *chr = [[[GenomeManager sharedGenomeManager] chromosomeAliasTable] objectForKey:[NSString stringWithUTF8String:header->target_name[i]]];
        if (nil == chr) {
            chr = [NSString stringWithUTF8String:header->target_name[i]];
        }

        [self.chrLookupTable setObject:[NSString stringWithUTF8String:header->target_name[i]] forKey:chr];
    }

    NSString *errorDetailString = nil;

    const char *remoteIndexFileURL;
    if (self.indexPath) {

//        remoteIndexFileURL = [self.indexPath UTF8String];

        remoteIndexFileURL = calloc(strlen([self.indexPath UTF8String]), 1);
        strcpy(remoteIndexFileURL, [self.filePath UTF8String]);

    } else {

        remoteIndexFileURL = calloc(strlen([self.filePath UTF8String]) + 5, 1);
        strcat(strcpy(remoteIndexFileURL, [self.filePath UTF8String]), ".bai");
    }

    knetFile *fp_remote = 0;
    uint8_t *buffer = 0;

    fp_remote = knet_open(remoteIndexFileURL, "r");
    if (0 == fp_remote) {

        errorDetailString = [NSString stringWithFormat:@"ERROR: knet_open(%@) returns 0 for BAM(%@)", [NSString stringWithUTF8String:remoteIndexFileURL], self.filePath];
        *error = [IGVHelpful errorWithDetailString:errorDetailString];
        ALog(@"0 == fp_remote. %@", [*error localizedDescription]);

        goto bailout;
    }

    NSString *indexFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"index.bai"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager createFileAtPath:indexFilename contents:nil attributes:nil]) {

        errorDetailString = [NSString stringWithFormat:@"ERROR: Can't create file at path %@", indexFilename];
        *error = [IGVHelpful errorWithDetailString:errorDetailString];
        ALog(@"NO == [fileManager createFileAtPath:contents:attributes:]. %@", [*error localizedDescription]);

        goto bailout;
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:indexFilename];
    if (nil == fileHandle) {

        errorDetailString = [NSString stringWithFormat:@"ERROR: Can't create filehandle at path %@", indexFilename];
        *error = [IGVHelpful errorWithDetailString:errorDetailString];

        ALog(@"nil == [NSFileHandle fileHandleForWritingAtPath:]. %@", [*error localizedDescription]);

        goto bailout;
    }

    const int bufferSize = 1 * 1024 * 1024;
    buffer = (uint8_t *) calloc((size_t) bufferSize, 1);

    off_t count;
    while ((count = knet_read(fp_remote, buffer, bufferSize)) != 0) {

        [fileHandle writeData:[NSData dataWithBytes:buffer length:(NSUInteger)count]];
    }
    [fileHandle closeFile];

    _index = bam_index_load_local([indexFilename UTF8String]);

    if (0 == _index) {

        errorDetailString = [NSString stringWithFormat:@"ERROR: bam_index_load_local(%@) failed for BAM(%@)", indexFilename, self.filePath];
        *error = [IGVHelpful errorWithDetailString:errorDetailString];

        ALog(@"0 == _index. %@", [*error localizedDescription]);

        goto bailout;
    }

bailout:;

    // clean up
    if (buffer) free(buffer);
    if (fp_remote) knet_close(fp_remote);
    if (remoteIndexFileURL) free(remoteIndexFileURL);

    if ([IGVHelpful errorDetected:*error]) {

        _index = 0;
        samclose(_samFile);
    }

    return [IGVHelpful errorDetected:*error] ? NO : YES;
}

@end
