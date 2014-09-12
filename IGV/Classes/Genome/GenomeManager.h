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
// Created by turner on 12/7/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>

//
static NSString *const kMyTracksListLabel = @"My Tracks";
//static NSString *const kPublicTracks      = @"Hosted Tracks";
static NSString *const kPublicTracks = @"Public Tracks";
static NSString *const kENCODELabel       = @"ENCODE";
//
static NSString *const kFastaSequenceFileKey = @"fastaSequenceFile";
static NSString *const kSequenceLocationKey = @"sequenceLocation";
static NSString *const kGeneFileKey = @"geneFile";
static NSString *const kCytobandFileKey = @"cytobandFile";
static NSString *const kEncodeFileKey = @"encodeFile";
//
static NSString *const kTrackMenuKey = @"trackMenu";
static NSString *const kLMCategoryItemsKey = @"LMCategoryItems";
//
static NSString *const kGeneTrackName = @"Genes";
//
//static NSString *const kGenomesFilePath = @"http://www.broadinstitute.org/igvdata/ipad/genomes_dat/genomes.txt";
static NSString *const kGenomesFilePath = @"http://www.broadinstitute.org/igvdata/ipad/genomes/genomes.txt";

@class Cytoband;
@class PListPersistence;
@class FastaSequence;

@interface GenomeManager : NSObject

@property(nonatomic, retain) PListPersistence *userDefinedGenomePersistence;
@property(nonatomic, assign) dispatch_queue_t dataRetrievalQueue;
@property(nonatomic, retain) NSMutableDictionary *genomeStubs;
@property(nonatomic, retain) NSMutableDictionary *cytobands;
@property(nonatomic, retain) NSString *currentGenomeName;
@property(nonatomic, retain) NSDictionary *chromosomeNames;
@property(nonatomic, retain) NSDictionary *chromosomeAliasTable;

- (void)loadGenomeWithContinuation:(void (^)(NSString *selectedGenomeName, NSError *error))continuation;
- (BOOL)loadCytobandWithGenomeName:(NSString *)genomeName error:(NSError **)error;
- (BOOL)loadGenomeStubsWithGenomePath:(NSString *)genomePath error:(NSError **)error;
- (void)initializeTrackMenuRoot;
- (BOOL)loadTrackMenuWithGenomeName:(NSString *)genomeName error:(NSError **)error;

- (FastaSequence *)currentFastaSequence;
- (NSDictionary *)currentGenomeStub;
- (NSDictionary *)currentTrackMenu;
- (Cytoband *)currentCytoband;
- (NSArray *)currentChromosomeExtent;
- (NSString *)chromosomeAliasForString:(NSString *)string;
- (NSArray *)chromosomeExtentWithChromosomeName:(NSString *)chromosomeName;
- (long long int)deltaBetweenEndOfChromosomeName:(NSString *)chromosomeName andValue:(long long int)value;
- (NSString *)firstChromosomeName;
- (BOOL)cytobandExistsForGenomeName:(NSString *)genomeName;
- (NSArray *)chromosomeNamesWithGenomeName:(NSString *)genomeName;
- (NSIndexPath *)indexPathWithCurrentGenomeName;
- (NSArray *)genomeNames;
- (NSString *)tableViewLabelTextWithIndex:(NSInteger)index;

- (BOOL)encodeFileExistsForGenomeName:(NSString *)genomeName;

- (void)mergeUserDefinedGenomesIntoGenomeStubs;

+ (GenomeManager *)sharedGenomeManager;

- (BOOL)isUserDefinedGenomeAtIndex:(NSInteger)index;

+ (BOOL)isValideGenomeName:(NSString *)candidateGenomeName;

- (void)deleteUserDefinedGenomeAtIndex:(NSInteger)index continuation:(void (^)(void))continuation;
@end