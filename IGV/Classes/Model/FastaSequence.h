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
//  FastaSequence.h
//  IGV
//
//  Created by turner on 5/16/14.
//
//
@class FeatureInterval;
@class GenomicInterval;

@interface FastaSequence : NSObject
- (id)initWithPath:(NSString *)path indexFile:(NSString *)indexFile;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSString *indexFile;
@property(nonatomic, retain) GenomicInterval *genomicInterval;
@property(nonatomic, retain) NSArray *rawChromosomeNames;

@property(nonatomic, retain) NSDictionary *fastaIndex;

- (NSArray *)chromosomeExtentWithChromosomeName:(NSString *)chromosomeName;
- (void)getSequenceWithGenomicInterval:(GenomicInterval *)genomicInterval continuation:(void (^)(NSString* sequenceString))continuation;
- (void)readSequenceWithChromosome:(NSString *)chromosome queryStart:(long long int)queryStart  queryEnd:(long long int)queryEnd continuation:(void (^)(NSString* sequenceString))continuation;

- (void)loadFastaIndexWithContinuation:(void (^)(void))continuation;

- (NSString *)firstChromosomeName;
@end
