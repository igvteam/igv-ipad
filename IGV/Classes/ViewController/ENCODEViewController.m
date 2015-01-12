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
//  ENCODEViewController.m
//  IGV
//
//  Created by turner on 1/22/14.
//
//

#import "ENCODEViewController.h"
#import "GenomeManager.h"
#import "ENCODETableViewCell.h"
#import "UINib-View.h"
#import "ENCODEItem.h"
#import "Logging.h"
#import "IGVMath.h"
#import "Codec.h"
#import "IGVHelpful.h"
#import "LMResource.h"
#import "RootContentController.h"
#import "UIApplication+IGVApplication.h"

@interface ENCODEViewController ()
@property(nonatomic, retain) NSMutableArray *encodeItems;
@property(nonatomic, retain) NSMutableArray *filterEncodeItems;
@property(nonatomic, retain) UINib *tableViewCellFromNib;
@property(nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property(nonatomic, retain) IBOutlet UITableView *tableView;
@property(nonatomic, retain) UISearchDisplayController *searchController;
@property(nonatomic, retain) IBOutlet UIView *columnNameView;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
- (void)doDismiss;
- (void)doLoadTracks;
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope;
+ (NSString *)trackLabelWithENCODEItem:(ENCODEItem *)encodeItem;
@end

@implementation ENCODEViewController

@synthesize encodeItems = _encodeItems;
@synthesize filterEncodeItems = _filterEncodeItems;
@synthesize tableViewCellFromNib = _tableViewCellFromNib;
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize searchController = _searchController;
@synthesize columnNameView = _columnNameView;
@synthesize spinner = _spinner;

- (void)dealloc {

    self.encodeItems = nil;
    self.filterEncodeItems = nil;
    self.tableViewCellFromNib = nil;
    self.searchBar = nil;
    self.tableView = nil;
    self.searchController = nil;
    self.columnNameView = nil;
    self.spinner = nil;

    [super dealloc];
}

+ (NSString *)trackLabelWithENCODEItem:(ENCODEItem *)encodeItem {

    NSString *antibodyString = [NSString stringWithFormat:@"%@ %@ %@", encodeItem.antibody, encodeItem.cell, encodeItem.replicate];
    NSString *noAntibodyString = [NSString stringWithFormat:@"%@ %@ %@ %@", encodeItem.cell, encodeItem.dataType, encodeItem.view, encodeItem.replicate];

    return (encodeItem.antibody) ? antibodyString : noAntibodyString;

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

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView setSeparatorColor:[UIColor whiteColor]];

    // set up search
    self.searchBar.keyboardType = UIKeyboardTypeWebSearch;

    self.searchController = [[[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self] autorelease];
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;

    // set up navBar toolBar buttons and shims
    UIBarButtonItem *shim = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil] autorelease];




    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [dismissButton setTitle:@"Dismiss" forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(doDismiss) forControlEvents:UIControlEventTouchUpInside];
    dismissButton.frame = CGRectMake(0, 0, 150, 30);
    dismissButton.layer.cornerRadius = 4;
    dismissButton.layer.borderWidth = 1;
    dismissButton.layer.borderColor = dismissButton.currentTitleColor.CGColor;
    UIBarButtonItem *dismiss = [[[UIBarButtonItem alloc] initWithCustomView:dismissButton] autorelease];

//    UIBarButtonItem *dismiss = [[[UIBarButtonItem alloc] initWithTitle:@"Dismiss"
//                                                                 style:UIBarButtonItemStyleDone
//                                                                target:self
//                                                                action:@selector(doDismiss)] autorelease];







    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load Tracks" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(doLoadTracks) forControlEvents:UIControlEventTouchUpInside];
    loadButton.frame = CGRectMake(0, 0, 150, 30);
    loadButton.layer.cornerRadius = 4;
    loadButton.layer.borderWidth = 1;
    loadButton.layer.borderColor = loadButton.currentTitleColor.CGColor;
    UIBarButtonItem *loadTracks = [[[UIBarButtonItem alloc] initWithCustomView:loadButton] autorelease];

//    UIBarButtonItem *loadTracks = [[[UIBarButtonItem alloc] initWithTitle:@"Load Tracks"
//                                                                    style:UIBarButtonItemStyleDone
//                                                                   target:self
//                                                                   action:@selector(doLoadTracks)] autorelease];


    [self setToolbarItems:[NSArray arrayWithObjects:shim, loadTracks, shim, dismiss, shim, nil] animated:NO];

    // ingest encode file.
    NSString *workerQueue = @"org.broadinstitute.igv.encodeWorkerQueue";
    dispatch_async(dispatch_queue_create([workerQueue UTF8String], NULL), ^{

        NSString *path = [[[GenomeManager sharedGenomeManager].genomeStubs objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName] objectForKey:kEncodeFileKey];

        NSData *data = nil;
        if (nil != path) {

            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
            NSString *string = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
            NSArray *lines = [string componentsSeparatedByString:@"\n"];

            // slurp keys
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

                ENCODEItem *encodeItem = [[[ENCODEItem alloc] initWithDictionary:[NSDictionary dictionaryWithObjects:objs forKeys:keys]] autorelease];
                [self.encodeItems addObject:encodeItem];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });

    });

}

- (void)viewDidAppear:(BOOL)animated {
//    [self.spinner stopAnimating];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)doDismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doLoadTracks {

    [self doDismiss];

    NSMutableArray *resources = [NSMutableArray array];

    NSArray *enabledENCODEItems = [self retrieveEnabledENCODEItems];
    for (ENCODEItem *enabledENCODEItem in enabledENCODEItems) {

        NSString *blurb = nil;
        BOOL success = [IGVHelpful isSupportedPath:enabledENCODEItem.path blurb:&blurb];

        if (blurb) {
            ALog(@"%@", blurb) ;
        }

        if (!success) {
            continue;
        }

        [resources addObject:[LMResource resourceWithName:[ENCODEViewController trackLabelWithENCODEItem:enabledENCODEItem] filePath:enabledENCODEItem.path]];
    }

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController enableTracksWithResources:resources appLaunchLocusCentroid:nil];

}

- (NSArray *)retrieveEnabledENCODEItems {

    NSMutableArray *enabledENCODEItems = [NSMutableArray array];
    for (ENCODEItem *encodeItem in self.encodeItems) {
        if (encodeItem.enabled) {
            [enabledENCODEItems addObject:encodeItem];
        }
    }

    return enabledENCODEItems;
}

- (void)encodeTableViewCell:(ENCODETableViewCell *)encodeTableViewCell trackSelectionToggle:(BOOL)trackSelectionToggle {

    NSIndexPath *indexPath = [encodeTableViewCell.tableView indexPathForCell:encodeTableViewCell];

    NSMutableArray *array = (encodeTableViewCell.tableView == self.searchDisplayController.searchResultsTableView) ? self.filterEncodeItems : self.encodeItems;
    ENCODEItem *encodeItem = [array objectAtIndex:(NSUInteger)indexPath.row];
    encodeItem.enabled = trackSelectionToggle;
}

#pragma mark - UISearchDisplayController Delegate Methods

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {

    // reposition searchResultsTableView vertically below column name view
    CGRect fr = tableView.frame;
    fr.origin.y = CGRectGetHeight(self.columnNameView.frame);
    tableView.frame = fr;
    [tableView.superview bringSubviewToFront:tableView];

}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {

    [self filterContentForSearchText:searchString scope:nil];
    return YES;
}

//-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
//
//    NSArray *scopeButtonTitles = [self.searchDisplayController.searchBar scopeButtonTitles];
//    NSString *scope = [scopeButtonTitles objectAtIndex:(NSUInteger)[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
//
//    [self filterContentForSearchText:searchString scope:scope];
//
//    return YES;
//}

//-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
//
//    NSArray *scopeButtonTitles = [self.searchDisplayController.searchBar scopeButtonTitles];
//    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:[scopeButtonTitles objectAtIndex:(NSUInteger)searchOption]];
//
//    return YES;
//}

#pragma mark - UISearchDisplayController Related ENCODETableViewController Methods

-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {

    ALog(@"search %@", searchText);

    NSArray *tokens = [searchText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSMutableArray *columnSearches = [NSMutableArray array];
    NSMutableArray *stringSearches = [NSMutableArray array];

    for (NSString *token in tokens) {

        if ([token rangeOfString:@"="].location != NSNotFound) {
            [columnSearches addObject:token];
        } else if (! [token isEqualToString:@""]) {
            [stringSearches addObject:token];
        }
    }

    NSMutableArray *columnSearchPredicates = [NSMutableArray array];
    for (NSString *columnSearch in columnSearches) {

        NSString *column = [[columnSearch componentsSeparatedByString:@"="] objectAtIndex:0];
        NSString *value  = [[columnSearch componentsSeparatedByString:@"="] objectAtIndex:1];
        if ([value isEqualToString:@""]) {
            continue;
        }
//        [columnSearchPredicates addObject:[NSPredicate predicateWithFormat:@"SELF.%@ = %@", column, value]];
        [columnSearchPredicates addObject:[NSPredicate predicateWithFormat:@"SELF.%@ contains[c] %@", column, value]];
    }

    NSMutableArray *stringSearchPredicates = [NSMutableArray array];
    for (NSString *stringSearch in stringSearches) {

        [stringSearchPredicates addObject:[NSPredicate predicateWithFormat:@"SELF.line contains[c] %@", stringSearch]];
    }

    NSPredicate *compoundColumnSearchPredicate = nil;
    if ([columnSearchPredicates count] > 0) {
        compoundColumnSearchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithArray:columnSearchPredicates]];
    }

    NSPredicate *compoundStringSearchPredicate = nil;
    if ([stringSearchPredicates count] > 0) {

        compoundStringSearchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithArray:stringSearchPredicates]];
    }

    NSArray *cooked = [NSMutableArray arrayWithArray:self.encodeItems];
    if (nil != compoundColumnSearchPredicate) {
        cooked = [NSMutableArray arrayWithArray:[cooked filteredArrayUsingPredicate:compoundColumnSearchPredicate]];
    }

    if (nil != compoundStringSearchPredicate) {
        cooked = [NSArray arrayWithArray:[cooked filteredArrayUsingPredicate:compoundStringSearchPredicate]];
    }

    self.filterEncodeItems = [NSMutableArray arrayWithArray:cooked];
}

//-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
//
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.line contains[c] %@", searchText];
//
//    [self.filterEncodeItems removeAllObjects];
//    self.filterEncodeItems = [NSMutableArray arrayWithArray:[self.encodeItems filteredArrayUsingPredicate:predicate]];
//}

#pragma mark - TableView Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    static CGFloat hgt = -1;
    if (-1 == hgt) {
        hgt = CGRectGetHeight([UINib containerViewBoundsForNibNamed:@"ENCODETableViewCell"]);
    }

    return hgt;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (tableView == self.searchDisplayController.searchResultsTableView) ? [self.filterEncodeItems count] : [self.encodeItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    ENCODETableViewCell *encodeTableViewCell = [ENCODETableViewCell cellForTableView:tableView fromNib:self.tableViewCellFromNib];
    encodeTableViewCell.controller = self;
    encodeTableViewCell.tableView = tableView;

    NSArray *items = (tableView == self.searchDisplayController.searchResultsTableView) ? self.filterEncodeItems : self.encodeItems;

    ENCODEItem *encodeItem = [items objectAtIndex:(NSUInteger)indexPath.row];

    encodeTableViewCell.cell.text = encodeItem.cell;
    encodeTableViewCell.dataType.text = encodeItem.dataType;

    encodeTableViewCell.antibody.text = encodeItem.antibody;
    encodeTableViewCell.view.text = encodeItem.view;

    encodeTableViewCell.replicate.text = encodeItem.replicate;
    encodeTableViewCell.type.text = encodeItem.type;

    encodeTableViewCell.lab.text = encodeItem.lab;
//    encodeTableViewCell.hub.text = encodeItem.hub;

    [encodeTableViewCell.trackSelectionSwitch setOn:encodeItem.enabled animated:NO];

    return encodeTableViewCell;
}

- (UINib *)tableViewCellFromNib {

    if (nil == _tableViewCellFromNib) {
        self.tableViewCellFromNib = [UINib nibWithNibName:@"ENCODETableViewCell" bundle:nil];
    }
    return _tableViewCellFromNib;
}

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}

@end
