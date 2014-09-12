//
//  NSPredicateTests.m
//  IGV
//
//  Created by turner on 1/24/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "ENCODEItem.h"
#import "Logging.h"

@interface NSPredicateTests : SenTestCase
@property(nonatomic, retain) NSMutableArray *encodeItems;
@property(nonatomic, retain) NSMutableArray *filterEncodeItems;
@end

@implementation NSPredicateTests

@synthesize encodeItems = _encodeItems;
@synthesize filterEncodeItems = _filterEncodeItems;

- (void)dealloc {

    self.encodeItems = nil;
    self.filterEncodeItems = nil;

    [super dealloc];
}

- (NSMutableArray *)encodeItems {
    if (nil == _encodeItems) {
        self.encodeItems = [NSMutableArray array];
    }
    return _encodeItems;
}

- (NSMutableArray *)filterEncodeItems {
    if (nil == _filterEncodeItems) {
        self.filterEncodeItems = [NSMutableArray array];
    }
    return _filterEncodeItems;
}

-(void) testENCODEColumnSearch {

    NSString *kk = @"path\tcell\tdataType\tantibody\tview\treplicate\ttype\tlab\thub";
    NSString *a = @"http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeAwgDnaseUniform/wgEncodeAwgDnaseDuke8988tUniPk.narrowPeak.gz\t8988T\tDnaseSeq\t\tPeaks\t\tnarrowPeak\tDuke\tData";
    NSString *b = @"http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeSydhNsome/wgEncodeSydhNsomeGm12878AlnRep3.bam\tGM12878\tNucleosome\t\tAlignments\t3\tbam\tStanford\tData";
    NSString *c = @"http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeSydhTfbs/wgEncodeSydhTfbsHelas3Corestsc30189IggrabPk.narrowPeak.gz\tHeLa-S3\tChipSeq\tCOREST_(sc-30189)\tPeaks\t\tnarrowPeak\tStanford\tData";
    NSArray *lines = [NSArray arrayWithObjects:kk, a, b, c, nil];

    NSArray *keys = [[lines objectAtIndex:0] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    for (NSUInteger i = 1; i < [lines count]; i++) {

        NSString *line = [lines objectAtIndex:i];
        if ([line isEqualToString:@""]) {
            continue;
        }

        // Insert human readable symbol (*) for empty strings in line
        line = [[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@"#"];
        line = [line stringByReplacingOccurrencesOfString:@"##" withString:@"#*#"];

        // slurp objects for keys
        NSArray *objs = [line componentsSeparatedByString:@"#"];

        NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
//        ALog(@"%@", dictionary);

        ENCODEItem *encodeItem = [[[ENCODEItem alloc] initWithDictionary:dictionary] autorelease];
        [self.encodeItems addObject:encodeItem];
    }


    NSString *searchText = @" stan view=Peaks type=narrowPeak";

    NSArray *tokens = [searchText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSMutableArray *columnSearchs = [NSMutableArray array];
    NSMutableArray *stringSearchs = [NSMutableArray array];

    for (NSString *token in tokens) {

        if ([token rangeOfString:@"="].location != NSNotFound) {
            [columnSearchs addObject:token];
        } else if (! [token isEqualToString:@""]) {
            [stringSearchs addObject:token];
        }
    }

    NSMutableArray *columnSearchPredicates = [NSMutableArray array];
    for (NSString *columnSearch in columnSearchs) {

        NSString *column = [[columnSearch componentsSeparatedByString:@"="] objectAtIndex:0];
        NSString *value  = [[columnSearch componentsSeparatedByString:@"="] objectAtIndex:1];
        [columnSearchPredicates addObject:[NSPredicate predicateWithFormat:@"SELF.%@ = %@", column, value]];
    }

    NSMutableArray *stringSearchPredicates = [NSMutableArray array];
    for (NSString *stringSearch in stringSearchs) {

        [stringSearchPredicates addObject:[NSPredicate predicateWithFormat:@"SELF.line contains[c] %@", stringSearch]];
    }

    ALog(@"%@", self.encodeItems);

    NSPredicate *compoundColumnSearchPredicate = nil;
    if ([columnSearchPredicates count] > 0) {
        compoundColumnSearchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithArray:columnSearchPredicates]];
    }

    NSPredicate *compoundStringSearchPredicate = nil;
    if ([stringSearchPredicates count] > 0) {
        compoundStringSearchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithArray:stringSearchPredicates]];
    }

    NSArray *cooked = nil;
    if (nil != compoundColumnSearchPredicate) {
        cooked = [NSMutableArray arrayWithArray:[self.encodeItems filteredArrayUsingPredicate:compoundColumnSearchPredicate]];
    }

    if (nil != compoundStringSearchPredicate) {
        cooked = [NSArray arrayWithArray:[cooked filteredArrayUsingPredicate:compoundStringSearchPredicate]];
    }

    self.filterEncodeItems = [NSMutableArray arrayWithArray:cooked];

    ALog(@"%@", self.filterEncodeItems);
}

@end
