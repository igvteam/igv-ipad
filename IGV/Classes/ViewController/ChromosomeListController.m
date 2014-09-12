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
//  ChromosomeListController.m
//  IGV
//
//  Created by turner on 5/12/14.
//
//

#import "ChromosomeListController.h"
#import "RootContentController.h"
#import "UIApplication+IGVApplication.h"
#import "GenomeManager.h"
#import "GenomeNameListController.h"
#import "NSString+FileURLAndLocusParsing.h"
#import "LocusListItem.h"
#import "Cytoband.h"
#import "FastaSequence.h"
#import "FastaSequenceManager.h"
#import "GenomicInterval.h"

NSInteger kChromosomeLabelTag = 44;

@implementation ChromosomeListController

@synthesize genomeName = _genomeName;
@synthesize chromosomeNames = _chromosomeNames;

- (void)dealloc {

    self.genomeName = nil;
    self.chromosomeNames = nil;

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;

}

- (void)viewWillAppear:(BOOL)animated {

    if ([[GenomeManager sharedGenomeManager].cytobands objectForKey:self.genomeName]) {

        Cytoband *cytoband = [[GenomeManager sharedGenomeManager].cytobands objectForKey:self.genomeName];
        self.chromosomeNames = cytoband.rawChromsomeNames;
        [self.tableView reloadData];
    } else {

        NSDictionary *genomeStub = [[GenomeManager sharedGenomeManager].genomeStubs objectForKey:self.genomeName];
        NSString *path = [genomeStub objectForKey:kFastaSequenceFileKey];
        FastaSequence *fastaSequence = [[FastaSequenceManager sharedFastaSequenceManager] fastaSequenceWithPath:path indexFile:nil];

        [fastaSequence loadFastaIndexWithContinuation:^() {

           self.chromosomeNames = fastaSequence.rawChromosomeNames;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }

}

- (NSArray *)chromosomeNames {

    if (nil == _chromosomeNames) {
        self.chromosomeNames = [NSArray array];
    }

    return _chromosomeNames;
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.chromosomeNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChromosomeListReuseIdentifier" forIndexPath:indexPath];
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];

    UILabel *label = (UILabel *)[cell.contentView viewWithTag:kChromosomeLabelTag];
    label.text = [self.chromosomeNames objectAtIndex:(NSUInteger)indexPath.row];

    return cell;
}

#pragma mark - UITableViewDelegate Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // dismiss genome list popover
    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.genomeListPopoverController dismissPopoverAnimated:YES];
    [rootContentController popoverControllerDidDismissPopover:rootContentController.genomeListPopoverController];

    LocusListItem *locusListItem = nil;

    if ([[GenomeManager sharedGenomeManager].currentGenomeName isEqualToString:self.genomeName]) {

        locusListItem = [[[LocusListItem alloc] initWithLocus:[self.chromosomeNames objectAtIndex:(NSUInteger)indexPath.row]
                                                                       label:nil
                                                             locusListFormat:LocusListFormatChrFullExtent
                                                                  genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

        dispatch_async(dispatch_get_main_queue(), ^{
            [rootContentController selectLocusListItem:locusListItem];
        });

    } else {

        [GenomeManager sharedGenomeManager].currentGenomeName = self.genomeName;

        locusListItem = [[[LocusListItem alloc] initWithLocus:[self.chromosomeNames objectAtIndex:(NSUInteger)indexPath.row]
                                                        label:nil
                                              locusListFormat:LocusListFormatChrFullExtent
                                                   genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[GenomeManager sharedGenomeManager], @"genomeManager", locusListItem, @"locusListItem", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:GenomeSelectionDidChangeNotification object:dictionary];
    }

}

@end
