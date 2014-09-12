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
// Created by jrobinso on 7/18/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "TDFReader.h"
#import "URLDataLoader.h"
#import "Logging.h"
#import "LittleEndianByteBuffer.h"
#import "FileRange.h"
#import "TDFDataset.h"
#import "TDFTile.h"
#import "NSData+GZIP.h"
#import "TDFFixedTile.h"
#import "TDFVaryTile.h"
#import "TDFBedTile.h"
#import "TDFGroup.h"
#import "HttpResponse.h"
#import "IGVHelpful.h"

int const GZIP_FLAG = 0x01;

@implementation TDFReader {
}

@synthesize path = _path;
@synthesize version;
@synthesize compressed;
@synthesize trackLine;
@synthesize trackType;
@synthesize trackNames;
@synthesize datasetIndex;
@synthesize groupIndex;
@synthesize chromosomeNames;

- (void)dealloc {

    self.path = nil;
    self.trackLine = nil;
    self.trackType = nil;
    self.trackNames = nil;
    self.datasetIndex = nil;
    self.groupIndex = nil;
    self.chromosomeNames = nil;

    [super dealloc];
}

- (TDFReader *)initWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion {

    self = [super init];

    if (nil != self) {

        self.path = path;

        // read header - compute size of header
        [URLDataLoader loadDataWithPath:self.path forRange:[FileRange rangeWithPosition:0 byteCount:24] completion:^(HttpResponse *response_0) {

            if ([IGVHelpful errorDetected:response_0.error]) {
                completion(response_0);
                return;
            }

            LittleEndianByteBuffer *littleEndianByteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:response_0.receivedData];
            [littleEndianByteBuffer nextInt];  // 860243028   magic number

            self.version = [littleEndianByteBuffer nextInt];

            long long idxPosition = [littleEndianByteBuffer nextLong];
            int idxByteCount = [littleEndianByteBuffer nextInt];
            int nHeaderBytes = [littleEndianByteBuffer nextInt];

            // read header -- we're in a block, presumably on on the main queu, so we can do this synchronously
            HttpResponse *response_1 = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:[FileRange rangeWithPosition:24 byteCount:nHeaderBytes]];

            if ([IGVHelpful errorDetected:response_1.error]) {

                completion(response_1);
                return;
            }

            // parse header
            [self parseHeaderDataWithLittleEndianByteBuffer:[LittleEndianByteBuffer littleEndianByteBufferWithData:response_1.receivedData]];

            // read master index
            HttpResponse *response_2 = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:[FileRange rangeWithPosition:idxPosition byteCount:idxByteCount]];
            if ([IGVHelpful errorDetected:response_2.error]) {
                completion(response_2);
                return;
            }

            // parse master index
            [self parseMasterIndexWithLittleEndianByteBuffer:[LittleEndianByteBuffer littleEndianByteBufferWithData:response_2.receivedData]];

            HttpResponse *response_3 = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:[self.groupIndex objectForKey:@"/"]];
            // TODO -- what do we do with response_3?

            completion(response_3);

        }];


    }

    return self;
}

- (TDFReader *)initWithPath:(NSString *)aPath {

    self = [super init];

    if (nil != self) {
        self.path = aPath;
    }

    return self;
}

- (void)parseHeaderDataWithLittleEndianByteBuffer:(LittleEndianByteBuffer *)littleEndianByteBuffer {

    if (self.version > 2) {

        int nWFs = [littleEndianByteBuffer nextInt];
        for (int i = 0; i < nWFs; i++) {

            [littleEndianByteBuffer nextString];    // window function
        }
    }

    self.trackType = [littleEndianByteBuffer nextString];
    self.trackLine = [littleEndianByteBuffer nextString];

    NSInteger nTracks = [littleEndianByteBuffer nextInt];

    self.trackNames = [NSMutableArray array];

    for (int i = 0; i < nTracks; i++) {

        NSString *name = [littleEndianByteBuffer nextString];
        [self.trackNames addObject:name];
    }

    ALog(@"track names %@", self.trackNames);

    if (self.version > 2) {

        [littleEndianByteBuffer nextString];    // genomeID
        NSInteger flags = [littleEndianByteBuffer nextInt];
        self.compressed = (flags & GZIP_FLAG) != 0;
    } else {

        self.compressed = NO;
    }

}

- (void)parseMasterIndexWithLittleEndianByteBuffer:(LittleEndianByteBuffer *)littleEndianByteBuffer {

    NSUInteger nDatasets = (NSUInteger) [littleEndianByteBuffer nextInt];
    self.datasetIndex = [NSMutableDictionary dictionaryWithCapacity:nDatasets];
    self.chromosomeNames = [NSMutableSet setWithCapacity:nDatasets];

    for (int i = 0; i < nDatasets; i++) {

        NSString *name = [littleEndianByteBuffer nextString];
        long long fPosition = [littleEndianByteBuffer nextLong];
        int n = [littleEndianByteBuffer nextInt];
        FileRange *entry = [FileRange rangeWithPosition:fPosition byteCount:n];
        [self.datasetIndex setObject:entry forKey:name];

        NSArray *tokens = [name componentsSeparatedByString:@"/"];
        if (tokens.count > 1) {
            NSString *chrName = [tokens objectAtIndex:1];
            [self.chromosomeNames addObject:chrName];
        }
    }

    NSUInteger nGroups = (NSUInteger) [littleEndianByteBuffer nextInt];
    self.groupIndex = [NSMutableDictionary dictionaryWithCapacity:nGroups];

    for (int i = 0; i < nDatasets; i++) {
        NSString *name = [littleEndianByteBuffer nextString];
        long long fPosition = [littleEndianByteBuffer nextLong];
        int n = [littleEndianByteBuffer nextInt];
        FileRange *entry = [FileRange rangeWithPosition:fPosition byteCount:n];
        [self.groupIndex setObject:entry forKey:name];
    }

}

// TODO -- this method uses synchronous url requests -- insure it isn't called from main thread
- (TDFDataset *)loadDatasetForChromosome:(NSString *)chromosome zoom:(NSInteger)zoom windowFunction:(NSString *)windowFunction error:(NSError **)error {

    // Version 1 only had mean
    //String wf = getVersion() < 2 ? "" : "/" + windowFunction.toString();

    NSString *dsName = [NSString stringWithFormat:@"/%@/z%d/%@", chromosome, zoom, windowFunction];
    FileRange *idxEntry = [self.datasetIndex objectForKey:dsName];
    if (nil == idxEntry) {
        dsName = [NSString stringWithFormat:@"/%@/raw", chromosome];
        idxEntry = [self.datasetIndex objectForKey:dsName];
    }


    if (nil == idxEntry) {

        if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. nil == idxEntry. %s %d.", [self class], __PRETTY_FUNCTION__, __LINE__]];
        return nil;
    } else {

        HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:idxEntry];
        if (nil != response.error) {
            if (nil != error) *error = response.error;
            return nil;
        }

        if (nil == response.receivedData) {
            if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. no data. %s %d.", [self class], __PRETTY_FUNCTION__, __LINE__]];
            return nil;
        }

        return [TDFDataset datasetWithName:dsName data:response.receivedData reader:self];
    }

}

- (id)tileForDataset:(TDFDataset *)dataset number:(NSInteger)tileNumber {

    long long *positions = dataset.tilePositions;

    if (tileNumber >= dataset.tileCount) {
        return nil;
    }

    long long position = positions[tileNumber];
    if (position < 0) {
        // Indicates empty tile TODO -- return an empty tile?
        return nil;
    }
    int byteCount = dataset.tileSizes[tileNumber];

    if (byteCount <= 0) {
        return nil;  // This is the convention to indicate no data in the region covered by the tile
    }

    FileRange *range = [FileRange rangeWithPosition:position byteCount:byteCount];
    HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:range];

    if (nil != response.error) {

        ALog(@"%@. %@", [self class], [response.error localizedDescription]);
        return nil;
    }

    NSData *data = response.receivedData;
    if (self.compressed) {
        data = [response.receivedData gunzippedData];
    }

    LittleEndianByteBuffer *les = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    NSString *typeString = [les nextString];

    id <TDFTile> tile = nil;
    if ([typeString isEqualToString:@"fixedStep"]) {
        tile = [[[TDFFixedTile alloc] initWithBuffer:les forTracks:self.trackNames] autorelease];
    }
    else if ([typeString isEqualToString:@"variableStep"]) {
        tile = [[[TDFVaryTile alloc] initWithBuffer:les forTracks:self.trackNames] autorelease];
    }
    else if ([typeString isEqualToString:@"bed"]) {
        tile = [[[TDFBedTile alloc] initWithBuffer:les forTracks:self.trackNames] autorelease];
    }
    else if ([typeString isEqualToString:@"bedWithName"]) {
        tile = [[[TDFBedTile alloc] initWithBuffer:les forTracks:self.trackNames] autorelease];
    } else {
        NSError *error = [IGVHelpful errorWithDetailString:@"Unknown tile type"];
        ALog(@"%@. %@", [self class], [error localizedDescription]);
        return nil;
    }

    return tile;

}

@end