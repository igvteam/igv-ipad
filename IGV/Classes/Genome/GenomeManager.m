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


#import "NSArray+Cytoband.h"
#import "IGVContext.h"
#import "GenomeManager.h"
#import "Cytoband.h"
#import "LMTree.h"
#import "LMCategory.h"
#import "IGVHelpful.h"
#import "Logging.h"
#import "FastaSequence.h"
#import "FastaSequenceManager.h"
#import "PListPersistence.h"

@interface GenomeManager ()
@property(nonatomic, retain) NSMutableDictionary *trackMenus;

- (id)initWithGenomePersistence:(PListPersistence *)genomePersistence;
@end

@implementation GenomeManager

@synthesize genomeStubs = _genomeStubs;
@synthesize cytobands = _cytobands;
@synthesize trackMenus = _trackMenus;
@synthesize currentGenomeName = _currentGenomeName;
@synthesize dataRetrievalQueue = _dataRetrievalQueue;
@synthesize chromosomeNames = _chromosomeNames;
@synthesize chromosomeAliasTable = _chromosomeAliasTable;
@synthesize userDefinedGenomePersistence = _userDefinedGenomePersistence;

- (void)dealloc {

    self.genomeStubs = nil;
    self.cytobands = nil;
    self.trackMenus = nil;

    self.currentGenomeName = nil;
    self.chromosomeNames = nil;
    self.chromosomeAliasTable = nil;
    self.dataRetrievalQueue = nil;
    self.userDefinedGenomePersistence = nil;

    [super dealloc];
}

- (id)initWithGenomePersistence:(PListPersistence *)genomePersistence {

    self = [super init];
    if (self) {

        self.userDefinedGenomePersistence = genomePersistence;
        BOOL success = [self.userDefinedGenomePersistence usePListPrefix:@"defaultUserDefinedGenome"];
        if (!success) {
           self = nil;
        }
    }
    return self;
}

- (void)loadGenomeWithContinuation:(void (^)(NSString *selectedGenomeName, NSError *error))continuation {

    dispatch_async(self.dataRetrievalQueue, ^{

        NSError *error = nil;
        error = nil;
        BOOL status = [self loadGenomeStubsWithGenomePath:kGenomesFilePath error:&error];
        if (!status) {
            continuation(nil, error);
            return;
        }

        // preload cytobands
        status = YES;
        for (id key in [self.genomeStubs allKeys]) {

            if ([self cytobandExistsForGenomeName:key]) {
                error = nil;
                status = [self loadCytobandWithGenomeName:key error:&error];
                if (!status) {
                    continuation(nil, error);
                    return;
                }

            }
        }

        continuation(nil, error);

    });

}

- (BOOL)loadGenomeStubsWithGenomePath:(NSString *)genomePath error:(NSError **)error {

    if (![IGVHelpful isReachablePath:genomePath]) {

        if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. Error retrieving data from path %@", [self class], genomePath]];
        return NO;
    }

    NSMutableDictionary *stubs = [NSMutableDictionary dictionary];

    NSData *genomeListData = [NSData dataWithContentsOfURL:[NSURL URLWithString:genomePath]];
    if (nil == genomeListData) {

        if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. Error retrieving data from path %@", [self class], genomePath]];
        return NO;
    }

    NSString *genomeListString = [[[NSString alloc] initWithBytes:[genomeListData bytes] length:[genomeListData length] encoding:NSUTF8StringEncoding] autorelease];

    NSMutableArray *genomeDescriptionList = [NSMutableArray arrayWithArray:[genomeListString componentsSeparatedByString:@"#genome"]];
    [genomeDescriptionList removeObject:@""];

    for (NSString *genomeDescription in genomeDescriptionList) {

        NSMutableArray *lines = [NSMutableArray arrayWithArray:[genomeDescription componentsSeparatedByString:@"\n"]];
        [lines removeObject:@""];

        id key = nil;
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
        for (NSString *line in lines) {

            if (NSNotFound != [line rangeOfString:@"#"].location /*&& 0 == [line rangeOfString:@"#"].location*/) {
                continue;
            }

            NSArray *key_value = [line componentsSeparatedByString:@"="];
            if (0 == [lines indexOfObject:line]) {

                key = [key_value objectAtIndex:1];
            } else {

                [mutableDictionary setObject:[key_value objectAtIndex:1] forKey:[key_value objectAtIndex:0]];
            }


        }

        if (nil != key) {
            [stubs setObject:mutableDictionary forKey:key];
        }

    }


    if (!self.currentGenomeName) {

        self.currentGenomeName = ([stubs objectForKey:@"hg19"]) ? @"hg19" : [[stubs allKeys] objectAtIndex:0];
    } else {

        // Add currently selected genome to dictionary. If the file at genomePath contains data for the same
        // genomeName that data will clobber it.
        if (![stubs objectForKey:self.currentGenomeName]) {

            [stubs setObject:[self.genomeStubs objectForKey:self.currentGenomeName] forKey:self.currentGenomeName];
        }

    }

    self.genomeStubs = stubs;

    [self mergeUserDefinedGenomesIntoGenomeStubs];

    return YES;
}

- (BOOL)loadTrackMenuWithGenomeName:(NSString *)genomeName error:(NSError **)error {

    NSString *path = [[self.genomeStubs objectForKey:genomeName] objectForKey:kTrackMenuKey];

    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
    if (nil == data) {

        if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. Error retrieving data from path %@", [self class], path]];
        return NO;
    }

    NSString *string = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];

    NSMutableArray *xmlPaths = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
    [xmlPaths removeObject:@""];

    // Add LMTrees to categoryItems
    NSMutableArray *categoryItems = [NSMutableArray array];
    for (NSString *xmlPath in xmlPaths) {

        LMTree *tree = [LMTree treeWithPath:xmlPath error:error];
        if (nil == tree) {
            return NO;
        }

        [tree.rootCategory cullAssessment];
        [tree.rootCategory cullChildCategories];

        if (!tree.rootCategory.canCull) {
            [categoryItems addObject:tree.rootCategory];
        }
    }

    [[self.trackMenus objectForKey:genomeName] setObject:categoryItems
                                                  forKey:kLMCategoryItemsKey];

    return YES;
}

- (BOOL)loadCytobandWithGenomeName:(NSString *)genomeName error:(NSError **)error {

    NSString *path = [[self.genomeStubs objectForKey:genomeName] objectForKey:kCytobandFileKey];
    Cytoband *cytoband = [[[Cytoband alloc] initWithPath:path] autorelease];

    if (nil == cytoband) {
        if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. Error retrieving cytoband data from path %@", [self class], kCytobandFileKey]];
        return NO;
    }

    [self.cytobands setObject:cytoband forKey:genomeName];

    return YES;
}

- (void)initializeTrackMenuRoot {

    [self.trackMenus setObject:[NSMutableDictionary dictionary] forKey:self.currentGenomeName];

    if (nil == [[self currentGenomeStub] objectForKey:kTrackMenuKey]) {

        [[self.trackMenus objectForKey:self.currentGenomeName] setObject:[NSArray arrayWithObject:kMyTracksListLabel] forKey:kTrackMenuKey];
    } else {

        [[self.trackMenus objectForKey:self.currentGenomeName] setObject:[NSArray arrayWithObjects:kPublicTracks, kMyTracksListLabel, nil] forKey:kTrackMenuKey];
    }
}

- (NSArray *)currentChromosomeExtent {

    NSString *chromosomeName = [IGVContext sharedIGVContext].chromosomeName;
    return [self chromosomeExtentWithChromosomeName:chromosomeName];
}

- (NSArray *)chromosomeExtentWithChromosomeName:(NSString *)chromosomeName {

    NSArray *chromosomeExtent = nil;
    if ([self currentCytoband]) {
        chromosomeExtent = [[self currentCytoband] chromosomeExtentWithChromosomeName:chromosomeName];

//        chromosomeExtent = [[self currentCytoband].chromosomes objectForKey:chromosomeName];
    } else {
        chromosomeExtent = [[self currentFastaSequence] chromosomeExtentWithChromosomeName:chromosomeName];
    }

    return chromosomeExtent;
}

- (FastaSequence *)currentFastaSequence {

    NSDictionary *genomeStub = [self currentGenomeStub];
    NSString *path = [genomeStub objectForKey:kFastaSequenceFileKey];
    if (nil == path) {
        return nil;
    }

    FastaSequence *fastaSequence = [[FastaSequenceManager sharedFastaSequenceManager] fastaSequenceWithPath:path indexFile:nil];
    if (nil == fastaSequence) {
        return nil;
    }

    return fastaSequence;
}

- (NSDictionary *)currentGenomeStub {
    return [self.genomeStubs objectForKey:self.currentGenomeName];
}

- (NSDictionary *)currentTrackMenu {
    return [self.trackMenus objectForKey:self.currentGenomeName];
}

- (Cytoband *)currentCytoband {
    return [self.cytobands objectForKey:self.currentGenomeName];
}

- (NSMutableDictionary *)genomeStubs {

    if (nil == _genomeStubs) {
        self.genomeStubs = [NSMutableDictionary dictionary];
    }

    return _genomeStubs;
}

- (NSMutableDictionary *)cytobands {

    if (nil == _cytobands) {
        self.cytobands = [NSMutableDictionary dictionary];
    }

    return _cytobands;
}

- (NSMutableDictionary *)trackMenus {

    if (nil == _trackMenus) {
        self.trackMenus = [NSMutableDictionary dictionary];
    }

    return _trackMenus;
}

- (dispatch_queue_t)dataRetrievalQueue {

    if (nil == _dataRetrievalQueue) {

        NSString *queueName = [NSString stringWithFormat:@"org.broadinstitute.igv.%@.data", [GenomeManager class]];
        self.dataRetrievalQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }

    return _dataRetrievalQueue;
}

- (NSDictionary *)chromosomeNames {

    if (nil == _chromosomeNames) {

        NSMutableArray *keys = [NSMutableArray array];
        NSMutableArray *objs = [NSMutableArray array];
        for (NSInteger i = 1; i < 23; ++i) {

            [keys addObject:[NSString stringWithFormat:@"%d", i]];
            [objs addObject:[NSString stringWithFormat:@"%d", i]];

            [keys addObject:[NSString stringWithFormat:@"chr%d", i]];
            [objs addObject:[NSString stringWithFormat:@"%d", i]];
        }

        [keys addObject:@"X"];
        [objs addObject:@"X"];

        [keys addObject:@"chrX"];
        [objs addObject:@"X"];

        [keys addObject:@"Y"];
        [objs addObject:@"Y"];

        [keys addObject:@"chrY"];
        [objs addObject:@"Y"];

        self.chromosomeNames = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
    }

    return _chromosomeNames;
}

- (NSDictionary *)chromosomeAliasTable {

    if (nil == _chromosomeAliasTable) {

        NSMutableArray *keys = [NSMutableArray array];
        NSMutableArray *objs = [NSMutableArray array];
        for (NSInteger i = 1; i < 23; ++i) {
            [keys addObject:[NSString stringWithFormat:@"chr%d", i]];
            [objs addObject:[NSString stringWithFormat:@"%d", i]];
        }

        [keys addObject:@"chrX"];
        [objs addObject:@"X"];

        [keys addObject:@"chrY"];
        [objs addObject:@"Y"];

        self.chromosomeAliasTable = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
    }

    return _chromosomeAliasTable;
}

- (NSString *)chromosomeAliasForString:(NSString *)string {

    NSString *chr = [self.chromosomeAliasTable objectForKey:string];
    return chr == nil ? string : chr;
}

- (long long int)deltaBetweenEndOfChromosomeName:(NSString *)chromosomeName andValue:(long long int)value {

    NSArray *chromosomeExtent = [self chromosomeExtentWithChromosomeName:chromosomeName];
    return [chromosomeExtent end] - value;
}

- (NSString *)firstChromosomeName {

    if ([self currentCytoband]) {

        return [[self currentCytoband] firstChromosomeName];
    } else {

        return [[self currentFastaSequence] firstChromosomeName];
    }

}

- (BOOL)cytobandExistsForGenomeName:(NSString *)genomeName {

    return nil != [[self.genomeStubs objectForKey:genomeName] objectForKey:kCytobandFileKey];
}

- (NSArray *)chromosomeNamesWithGenomeName:(NSString *)genomeName {

    if ([self.cytobands objectForKey:genomeName]) {

        Cytoband *cytoband = [self.cytobands objectForKey:genomeName];
        return cytoband.rawChromsomeNames;
    } else {

        NSDictionary *genomeStub = [self.genomeStubs objectForKey:genomeName];
        NSString *path = [genomeStub objectForKey:kFastaSequenceFileKey];
        if (nil == path) {
            return nil;
        }

        FastaSequence *fastaSequence = [[FastaSequenceManager sharedFastaSequenceManager] fastaSequenceWithPath:path indexFile:nil];
        if (nil == fastaSequence) {
            return nil;
        }

        return fastaSequence.rawChromosomeNames;
    }

}

- (NSIndexPath *)indexPathWithCurrentGenomeName {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[self genomeNames] indexOfObject:self.currentGenomeName] inSection:0];
    return indexPath;

}

- (NSArray *)genomeNames {
    NSMutableArray *genomeNames = [NSMutableArray arrayWithArray:[[self.genomeStubs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    return genomeNames;
}

- (NSString *)tableViewLabelTextWithIndex:(NSInteger)index {
    id key = [[self genomeNames] objectAtIndex:(NSUInteger)index];
    NSDictionary *genomeStub = [self.genomeStubs objectForKey:key];
    return [genomeStub objectForKey:@"name"];
}

- (BOOL)encodeFileExistsForGenomeName:(NSString *)genomeName {
    NSDictionary *genomeStub = [self.genomeStubs objectForKey:genomeName];
    NSString *path = [genomeStub objectForKey:kEncodeFileKey];
    return nil != path;
}

- (void)mergeUserDefinedGenomesIntoGenomeStubs {

    NSDictionary *userDefinedGenomesPersistenceDictionary = [[GenomeManager sharedGenomeManager].userDefinedGenomePersistence plistDictionary];

    for (id userDefinedGenomeName in [userDefinedGenomesPersistenceDictionary allKeys]) {

        NSMutableDictionary *userGenerateGenomeStub = [NSMutableDictionary dictionaryWithDictionary:[userDefinedGenomesPersistenceDictionary objectForKey:userDefinedGenomeName]];

        // add "name" field for consistence with genome stub dictionary items from genomes.txt file
        [userGenerateGenomeStub setObject:userDefinedGenomeName forKey:@"name"];

        // indicate this is a user defined genome
        [userGenerateGenomeStub setObject:[NSNumber numberWithBool:YES] forKey:@"userDefined"];

        [self.genomeStubs setObject:userGenerateGenomeStub forKey:userDefinedGenomeName];
    }

}

+ (GenomeManager *)sharedGenomeManager {

    static dispatch_once_t pred;
    static GenomeManager *shared = nil;

    dispatch_once(&pred, ^{

        shared = [[GenomeManager alloc] initWithGenomePersistence:[[[PListPersistence alloc] init] autorelease]];
    });

    return shared;
}

- (BOOL)isUserDefinedGenomeAtIndex:(NSInteger)index {

    NSDictionary *genomeStub = [self.genomeStubs objectForKey:[[self genomeNames] objectAtIndex:(NSUInteger)index]];

    if (nil == [genomeStub objectForKey:@"userDefined"]) {

        return NO;
    } else {
        return [[genomeStub objectForKey:@"userDefined"] boolValue];
    }

}

+ (BOOL)isValideGenomeName:(NSString *)candidateGenomeName {

    BOOL success = NO;
    for (NSString *genomeName in [[GenomeManager sharedGenomeManager].genomeStubs allKeys]) {

        if ([candidateGenomeName isEqualToString:genomeName]) {
            success = YES;
            break;
        }

    }

    return success;
}

- (void)deleteUserDefinedGenomeAtIndex:(NSInteger)index continuation:(void (^)(void))continuation {

    id key = [[self genomeNames] objectAtIndex:(NSUInteger)index];
    [self.genomeStubs removeObjectForKey:key];

    NSMutableDictionary *dictionary = [self.userDefinedGenomePersistence plistDictionary];
    [dictionary removeObjectForKey:key];
    [self.userDefinedGenomePersistence writePListDictionary:dictionary];

    continuation();

}
@end