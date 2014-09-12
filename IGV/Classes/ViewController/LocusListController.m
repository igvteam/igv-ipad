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
//  LocusListController.m
//  IGV
//
//  Created by Douglass Turner on 3/20/13.
//
//

#import "LocusListController.h"
#import "UINib-View.h"
#import "LocusListItem.h"
#import "NSUserDefaults+LocusFileURL.h"
#import "RootContentController.h"
#import "UIApplication+IGVApplication.h"
#import "GenomeManager.h"
#import "LocusListTableViewCell.h"
#import "GenomeNameListController.h"

@interface LocusListController ()
@property(nonatomic, retain) UINib *tableViewCellFromNib;
@property(nonatomic, retain) NSMutableDictionary *loci;
- (void)initializationHelper;
- (void)genomeSelectionDidChangeWithNotification:(NSNotification *)notification;
- (void)presentLocusDialogControllerWithBarButtonItem:(UIBarButtonItem *)barButtonItem;
@end

@implementation LocusListController

@synthesize tableViewCellFromNib = _tableViewCellFromNib;
@synthesize loci = _loci;

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:GenomeSelectionDidChangeNotification object:nil];

    self.loci = nil;
    self.tableViewCellFromNib = nil;

    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (nil != self) {

        [self initializationHelper];
    }

    return self;
}

- (void)awakeFromNib {
    [self initializationHelper];
}

- (void)initializationHelper {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeSelectionDidChangeWithNotification:) name:GenomeSelectionDidChangeNotification object:nil];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self
                                                                                            action:@selector(presentLocusDialogControllerWithBarButtonItem:)] autorelease];

    NSArray *locusListDefaults = [[NSUserDefaults standardUserDefaults] arrayForKey:kLocusListDefaults];
    if (nil == locusListDefaults) {
        return;
    }

    for (NSDictionary *locusListDefaultsItem in locusListDefaults) {

        NSString *genome = [LocusListItem genomeWithLocusListDefaultsItem:locusListDefaultsItem];
        NSString *locus  = [LocusListItem  locusWithLocusListDefaultsItem:locusListDefaultsItem];
        NSString *label  = [LocusListItem  labelWithLocusListDefaultsItem:locusListDefaultsItem];

        if (nil == [self.loci objectForKey:genome]) {
            [self.loci setObject:[NSMutableArray array] forKey:genome];
        }

        NSMutableArray *loci = [self.loci objectForKey:genome];
        [loci addObject:[[[LocusListItem alloc] initWithLocus:locus label:label locusListFormat:[locus format] genomeName:genome] autorelease]];
    }
}

- (void)viewDidLoad {
    self.clearsSelectionOnViewWillAppear = YES;
}

- (NSMutableDictionary *)loci {

    if (nil == _loci) {
        self.loci = [NSMutableDictionary dictionary];
    }

    return _loci;
}

#pragma mark - LocusDialogDelegate methods

- (void)presentLocusDialogControllerWithBarButtonItem:(UIBarButtonItem *)barButtonItem {

    UINavigationController *navigationController = [[[UINib nibWithNibName:@"LocusDialogNavigationBar" bundle:nil] instantiateWithOwner:nil options:nil] objectAtIndex:0];
    navigationController.preferredContentSize = self.preferredContentSize;
    navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;

    LocusDialogController *locusDialogController = (LocusDialogController *) navigationController.topViewController;
    locusDialogController.preferredContentSize = self.preferredContentSize;
    locusDialogController.delegate = self;

    [self presentViewController:navigationController animated:YES completion:nil];

}

- (void)locusDialogController:(LocusDialogController *)locusDialogController addLocusListItem:(LocusListItem *)locusListItem {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    [rootContentController.locusListPopoverController dismissPopoverAnimated:YES];

    // NOTE: Call popoverControllerDelegate method explicitly since it is not called when we dismiss the popoverController programatically
    [rootContentController popoverControllerDidDismissPopover:rootContentController.locusListPopoverController];

    if (nil == locusListItem) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] addLocusListItem:locusListItem forKey:kLocusListDefaults];

    if (nil == [self.loci objectForKey:locusListItem.genome]) {
        [self.loci setObject:[NSMutableArray array] forKey:locusListItem.genome];
    }

    NSMutableArray *loci = [self.loci objectForKey:locusListItem.genome];
    [loci insertObject:locusListItem atIndex:0];

    [self.tableView reloadData];

    [rootContentController selectLocusListItem:locusListItem];
}

#pragma mark - Table view delegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectGetHeight([UINib containerViewBoundsForNibNamed:@"LocusListTableViewCell"]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.loci objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    LocusListTableViewCell *locusListTableViewCell = [LocusListTableViewCell cellForTableView:tableView fromNib:self.tableViewCellFromNib];

    NSMutableArray *locusList = [self.loci objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];
    LocusListItem *locusListItem = [locusList objectAtIndex:(NSUInteger)indexPath.row];
    locusListTableViewCell.label.text = [locusListItem tableViewCellLabel];
    locusListTableViewCell.locus.text = [locusListItem tableViewCellLocus];

    return locusListTableViewCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.locusListPopoverController dismissPopoverAnimated:YES];

    // NOTE: Call popoverControllerDelegate method explicitly since it is not called when
    // we dismiss the popoverController programatically
    [rootContentController popoverControllerDidDismissPopover:rootContentController.locusListPopoverController];

    NSMutableArray *locusList = [self.loci objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];
    [rootContentController selectLocusListItem:[locusList objectAtIndex:(NSUInteger) indexPath.row]];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {

        NSMutableArray *locusList = [self.loci objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];
        LocusListItem *locusListItem = [locusList objectAtIndex:(NSUInteger)indexPath.row];

        [[NSUserDefaults standardUserDefaults] removeLocusListItem:locusListItem forKey:kLocusListDefaults];
        [locusList removeObjectAtIndex:(NSUInteger)indexPath.row];

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {

    NSMutableArray *locusList = [self.loci objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];

    LocusListItem *locusListItem = [[locusList objectAtIndex:(NSUInteger)sourceIndexPath.row] retain];

    [locusList removeObjectAtIndex:(NSUInteger)sourceIndexPath.row];
    [locusList insertObject:locusListItem atIndex:(NSUInteger)destinationIndexPath.row];

    [locusListItem release];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Notification Callbacks

- (void)genomeSelectionDidChangeWithNotification:(NSNotification *)notification {
    [self.tableView reloadData];
}

#pragma mark - Nib Name

- (UINib *)tableViewCellFromNib {

    if (nil == _tableViewCellFromNib) {
        self.tableViewCellFromNib = [UINib nibWithNibName:@"LocusListTableViewCell" bundle:nil];
    }

    return _tableViewCellFromNib;
}

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}

@end
