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
//  FastaSequence.m
//  IGV
//
//  Created by turner on 5/16/14.
//
//

#import "FastaSequence.h"
#import "GenomicInterval.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "Logging.h"
#import "FileRange.h"
#import "GenomeManager.h"


@interface FastaSequence ()
+ (NSString *)getSequenceWithGenomicInterval:(GenomicInterval *)genomicInterval start:(long long int)start end:(long long int)end;
@end

@implementation FastaSequence

@synthesize path = _path;
@synthesize indexFile = _indexFile;
@synthesize genomicInterval = _genomicInterval;
@synthesize fastaIndex = _fastaIndex;
@synthesize rawChromosomeNames = _rawChromosomeNames;

- (void)dealloc {

    self.path = nil;
    self.indexFile = nil;
    self.genomicInterval = nil;
    self.fastaIndex = nil;
    self.rawChromosomeNames = nil;

    [super dealloc];
}

-(id)initWithPath:(NSString *)path indexFile:(NSString *)indexFile {

    self = [super init];
    if (self) {
        
        self.path = path;
        self.indexFile = (nil != indexFile) ? indexFile: [NSString stringWithFormat:@"%@.fai", self.path];
    }

    return self;
}

- (NSArray *)chromosomeExtentWithChromosomeName:(NSString *)chromosomeName {

    if (nil == self.fastaIndex) {
        return nil;
    }

    NSDictionary *chromosome = [self.fastaIndex objectForKey:chromosomeName];
    if (nil == chromosome) {
        return nil;
    }

    return [NSArray arrayWithObjects:[NSNumber numberWithInteger:0], [chromosome objectForKey:@"size"], nil];
}

- (void)getSequenceWithGenomicInterval:(GenomicInterval *)genomicInterval continuation:(void (^)(NSString* sequenceString))continuation; {

    __block GenomicInterval *selfGenomicInterval = self.genomicInterval;
    if(nil != self.genomicInterval && [self.genomicInterval containsFeatureInterval:genomicInterval]) {

        continuation([FastaSequence getSequenceWithGenomicInterval:selfGenomicInterval start:genomicInterval.start end:genomicInterval.end]);
    } else {

        // Expand query, to maximum of 100kb
        long long int qstart = genomicInterval.start;
        long long int qend = genomicInterval.end;

        static const int genomicIntervalLengthThreshold = 50000;
        if ((genomicInterval.end - genomicInterval.start) < genomicIntervalLengthThreshold) {

            long long int length = (genomicInterval.end - genomicInterval.start);
            double dcenter = ((double)genomicInterval.start) + ((double)length)/2.0;
            long long int center = (long long int) round(dcenter);

            qstart = center - genomicIntervalLengthThreshold/2;
            qend   = center + genomicIntervalLengthThreshold/2;
        }

        [self readSequenceWithChromosome:genomicInterval.chromosomeName queryStart:qstart queryEnd:qend continuation:^(NSString *sequenceString) {

            selfGenomicInterval = [[[GenomicInterval alloc] initWithChromosomeName:genomicInterval.chromosomeName start:qstart end:qend features:sequenceString] autorelease];
            continuation([FastaSequence getSequenceWithGenomicInterval:selfGenomicInterval start:genomicInterval.start end:genomicInterval.end]);
        }];

    }

}

- (void)readSequenceWithChromosome:(NSString *)chr queryStart:(long long int)qstart  queryEnd:(long long int)qend continuation:(void (^)(NSString * sequenceString))continuation {

    FastaSequence __unsafe_unretained *weakSelf = self;

    if (!self.fastaIndex) {

        [self loadFastaIndexWithContinuation:^() {
            [self readSequenceWithChromosome:chr queryStart:qstart queryEnd:qend continuation:continuation];
        }];

    } else {

        NSString *key = chr;
        NSDictionary *idxEntry = [self.fastaIndex objectForKey:key];
        if (!idxEntry) {
            key = [NSString stringWithFormat:@"chr%@", chr];
            idxEntry = [self.fastaIndex objectForKey:key];
        }

        if (!idxEntry) {

            ALog(@"Warning: No fasta index for %@", chr);

            // Tag interval with nil so we don't try again
            weakSelf.genomicInterval = [[[GenomicInterval alloc] initWithChromosomeName:chr start:qstart end:qend features:nil] autorelease];

            continuation(nil);

        } else {

            long long int start = MAX(0, qstart);
            long long int   end = MIN([[idxEntry objectForKey:@"size"] longLongValue], qend);

            NSInteger bytesPerLine = [[idxEntry objectForKey:@"bytesPerLine"] integerValue];
            NSInteger basesPerLine = [[idxEntry objectForKey:@"basesPerLine"] integerValue];
            long long int position = [[idxEntry objectForKey:@"position"] longLongValue];

            NSInteger nEndBytes = bytesPerLine - basesPerLine;

            NSInteger startLine = (NSInteger) floor(start / basesPerLine);
            NSInteger   endLine = (NSInteger) floor(  end / basesPerLine);

            NSInteger base0 = startLine * basesPerLine;   // Base at beginning of start line

            long long int offset = start - base0;

            long long int startByte = position + startLine * bytesPerLine + offset;

            NSInteger base1 = endLine * basesPerLine;
            long long int offset1 = end - base1;
            long long int endByte = position + endLine * bytesPerLine + offset1 - 1;

            // TODO - dat: this was needed to match the js implementation
            ++endByte;

            if (startByte >= endByte) {
                return;
            }

            [URLDataLoader loadDataWithPath:weakSelf.path
                                   forRange:[FileRange rangeWithPosition:startByte byteCount:(endByte-startByte)]
                                 completion:^(HttpResponse *httpResponse) {

                NSString *httpResponseDataString = [[[NSString alloc] initWithBytes:[httpResponse.receivedData bytes]
                                                                             length:[httpResponse.receivedData length]
                                                                           encoding:NSUTF8StringEncoding] autorelease];

                NSUInteger nBases, srcPos=0, desPos=0;
                NSString *sequenceString = @"";

                if (offset > 0) {

                    nBases = (NSUInteger)MIN(end - start, basesPerLine - offset);

                    sequenceString = [sequenceString stringByAppendingString:[httpResponseDataString substringWithRange:NSMakeRange(srcPos, nBases)]];

                    srcPos += (nBases + nEndBytes);
                    desPos += nBases;
                }

                while (srcPos < [httpResponseDataString length]) {

                    nBases = (NSUInteger)MIN(basesPerLine, [httpResponseDataString length] - srcPos);
                    if (nBases <= 0) {
                        ALog(@"ERROR: nBases %d is invalid", nBases);
                    }

                    NSRange range = NSMakeRange(srcPos, nBases);
                    NSString *subString = [httpResponseDataString substringWithRange:range];
                    if (nil == subString) {
                        ALog(@"ERROR: bad range %d %d. httpResponseDataString %d.", range.location, range.length, [httpResponseDataString length]);
                    }
                    sequenceString = [sequenceString stringByAppendingString:subString];

                    srcPos += (nBases + nEndBytes);
                    desPos += nBases;
                }

                continuation([sequenceString uppercaseString]);

            }];

        }

    }

}

- (void)loadFastaIndexWithContinuation:(void (^)(void))continuation {

    if (self.fastaIndex) {

        continuation();
    } else {

        FastaSequence __unsafe_unretained *weakSelf = self;

        [URLDataLoader loadDataWithPath:self.indexFile completion:^(HttpResponse *httpResponse) {

            NSData *fastaIndexData = httpResponse.receivedData;

            NSString *sequenceString = [[[NSString alloc] initWithBytes:[fastaIndexData bytes]
                                                                 length:[fastaIndexData length]
                                                               encoding:NSUTF8StringEncoding] autorelease];

            NSArray *lines = [sequenceString componentsSeparatedByString:@"\n"];

            NSMutableDictionary *fastaIndex = [NSMutableDictionary dictionary];
            NSMutableArray *rawChromosomeNames = [NSMutableArray array];
            [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger index, BOOL *stop) {

                NSArray *tokens = [line componentsSeparatedByString:@"\t"];
                if (5 == [tokens count]) {

                    NSString *chromosomeName = [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:tokens[0]];
                    if (chromosomeName) {

                        [rawChromosomeNames addObject:tokens[0]];

                        NSNumber *size         = [NSNumber numberWithLongLong:[tokens[1] longLongValue]];
                        NSNumber *position     = [NSNumber numberWithLongLong:[tokens[2] longLongValue]];
                        NSNumber *basesPerLine = [NSNumber numberWithInteger:[tokens[3] integerValue]];
                        NSNumber *bytesPerLine = [NSNumber numberWithInteger:[tokens[4] integerValue]];

                        NSArray *keys = [NSArray arrayWithObjects:@"size", @"position", @"basesPerLine", @"bytesPerLine", nil];
                        NSArray *objs = [NSArray arrayWithObjects:  size,    position,    basesPerLine,    bytesPerLine,  nil];
                        [fastaIndex setObject:[NSDictionary dictionaryWithObjects:objs forKeys:keys] forKey:chromosomeName];

                    }
                }

            }];

            weakSelf.fastaIndex = [NSDictionary dictionaryWithDictionary:fastaIndex];
            weakSelf.rawChromosomeNames = [NSArray arrayWithArray:rawChromosomeNames];

            continuation();

        }];

    }


}

+ (NSString *)getSequenceWithGenomicInterval:(GenomicInterval *)genomicInterval start:(long long int)start end:(long long int)end {

    long long int offset = start - genomicInterval.start;
    long long int length = end - start;
    NSString *sequenceString = (nil != genomicInterval.features) ? [genomicInterval.features substringWithRange:NSMakeRange((NSUInteger)offset, (NSUInteger)length)] : nil;
    return sequenceString;
}

- (NSString *)firstChromosomeName {
    return (nil == self.rawChromosomeNames) ? nil : [self.rawChromosomeNames objectAtIndex:0];
}


@end
