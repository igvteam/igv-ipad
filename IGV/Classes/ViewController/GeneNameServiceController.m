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


#import "GeneNameServiceController.h"
#import "LocusListTableViewCell.h"
#import "UINib-View.h"
#import "RootContentController.h"
#import "LocusListItem.h"
#import "GenomeManager.h"
#import "Logging.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "UIApplication+IGVApplication.h"

@interface GeneNameServiceController ()
@property(nonatomic, retain) UINib *tableViewCellFromNib;
@end

@implementation GeneNameServiceController

@synthesize tableViewCellFromNib;
@synthesize genes;

- (void)dealloc {

    self.tableViewCellFromNib = nil;
    self.genes = nil;

    [super dealloc];
}

- (id)initWithGenes:(NSArray *)aGenes NibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (nil != self) {

        self.genes = aGenes;
    }

    return self;
}

#pragma mark - Methods

+ (NSArray *)locusForGene:(NSString *)gene {

    NSString *urlString = [NSString stringWithFormat:@"http://www.broadinstitute.org/webservices/igv/locus?genome=%@&name=%@", [GenomeManager sharedGenomeManager].currentGenomeName, gene];
    return [GeneNameServiceController geneNameLookupResultsWithURLString:urlString];

}

+ (NSArray *)geneNameLookupResultsWithURLString:(NSString *)urlString {

    HttpResponse *httpResponse = [URLDataLoader loadDataSynchronousWithPath:urlString];
    NSData *data = [httpResponse receivedData];
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];

    if (nil == data) {
        return nil;
    }

    if (0 == [data length]) {
        return nil;
    }

    NSMutableString *string = [NSMutableString stringWithString:[[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease]];
    if (nil == string) {
        return nil;
    }

    if (0 == [string length]) {
        return nil;
    }


    // Split along newline boundaries yielding something of the form
    //
    //  "EDEM1\tchr3:5,204,358-5,236,650\trefseq"
    //
    NSArray *raw = [NSArray arrayWithArray:[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];

    // Discard items that match @""
    NSMutableArray *cooked = [NSMutableArray array];
    for (NSString *item in raw) {
        if (![item isEqualToString:@""]) [cooked addObject:item];
    }

    NSMutableArray *results = [NSMutableArray array];
    // Split into tokens along whitespace boundaries. Note: this includes tabs: \t
    for (NSString *line in cooked) {

        NSArray *tokens = [NSArray arrayWithArray:[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
//        [results setObject:[tokens objectAtIndex:1] forKey:[tokens objectAtIndex:0]];
        [results addObject:[NSArray arrayWithObjects:[tokens objectAtIndex:0], [tokens objectAtIndex:1], nil]];
    }

    return results;
}

#pragma mark - UITableView data source and delegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectGetHeight([UINib containerViewBoundsForNibNamed:@"LocusListTableViewCell"]);;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.genes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    LocusListTableViewCell *locusListTableViewCell = [LocusListTableViewCell cellForTableView:tableView fromNib:self.tableViewCellFromNib];

    locusListTableViewCell.label.text   = [NSString stringWithFormat:@"%@", [[self.genes objectAtIndex:(NSUInteger)indexPath.row] objectAtIndex:0]];
    locusListTableViewCell.locus.text   = [NSString stringWithFormat:@"%@", [[self.genes objectAtIndex:(NSUInteger)indexPath.row] objectAtIndex:1]];

    return locusListTableViewCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    if ([rootContentController.geneNameServicePopoverController isPopoverVisible]) {
        [rootContentController.geneNameServicePopoverController dismissPopoverAnimated:YES];
    }

    NSString *locus = [[self.genes objectAtIndex:(NSUInteger)indexPath.row] objectAtIndex:1];
    LocusListFormat format = [locus format];
    if (LocusListFormatInvalid != format) {

        LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:locus
                                                                       label:@""
                                                             locusListFormat:format
                                                                  genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

        [rootContentController selectLocusListItem:locusListItem];
    }

}

#pragma mark - Nib Name

- (UINib *)tableViewCellFromNib {

    if (nil == tableViewCellFromNib) {

        self.tableViewCellFromNib = [UINib nibWithNibName:@"LocusListTableViewCell" bundle:nil];
    }

    return tableViewCellFromNib;
}

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}

@end

