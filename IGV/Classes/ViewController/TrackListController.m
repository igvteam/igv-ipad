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
//  TrackListController.m
//  IGV
//
//  Created by Douglass Turner on 2/2/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "TrackListController.h"
#import "TrackController.h"
#import "TrackListTableViewCell.h"
#import "LMResource.h"
#import "LMCategory.h"
#import "UINib-View.h"
#import "MyTracksController.h"
#import "GenomeManager.h"
#import "FileListItem.h"
#import "UIApplication+IGVApplication.h"
#import "ENCODEViewController.h"
#import "NSUserDefaults+LocusFileURL.h"
#import "IGVHelpful.h"

@interface TrackListController ()
@property(nonatomic, retain) UINib *tableViewCellFromNib;
@property(nonatomic, assign) NSInteger nestingLevel;
@property(nonatomic, retain) NSMutableArray *items;
- (UIViewController *)controllerForTableViewItem:(id)tableViewItem;
@end

@implementation TrackListController

@synthesize tableViewCellFromNib;
@synthesize items;
@synthesize nestingLevel = _nestingLevel;

- (void)dealloc {

    self.tableViewCellFromNib = nil;
    self.items = nil;

    [super dealloc];
}

- (id)initWithList:(NSMutableArray *)list nestingLevel:(NSInteger)nestingLevel nibName:(void *)nibNameOrNil bundle:(void *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (nil != self) {

        self.items = list;
        self.nestingLevel = nestingLevel;
    }

    return self;
}

- (void)awakeFromNib {
    self.nestingLevel = -1;
}

- (void)viewWillAppear:(BOOL)animated {

    if (-1 == self.nestingLevel) {
        [[GenomeManager sharedGenomeManager] initializeTrackMenuRoot];
        self.items = [[[GenomeManager sharedGenomeManager] currentTrackMenu] objectForKey:kTrackMenuKey];
    }

    [self.tableView reloadData];
}

#pragma mark - viewController selector method

- (UIViewController *)controllerForTableViewItem:(id)tableViewItem {

    if ([tableViewItem isKindOfClass:[LMResource class]]) {
        return nil;
    }

    UIViewController *viewController = nil;

    if ([tableViewItem isKindOfClass:[LMCategory class]]) {

        LMCategory *category = (LMCategory *) tableViewItem;
        viewController = [[[TrackListController alloc] initWithList:[category resourceTreeControllerItems]
                                                       nestingLevel:(1 + self.nestingLevel)
                                                            nibName:nil
                                                             bundle:nil] autorelease];

    } else if ([tableViewItem isEqualToString:kMyTracksListLabel]) {

        viewController = [[[MyTracksController alloc] initWithNibName:nil bundle:nil] autorelease];

    } else if ([tableViewItem isEqualToString:kENCODELabel]) {

        ENCODEViewController *encodeController = [[[ENCODEViewController alloc] initWithNibName:nil bundle:nil] autorelease];

        UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:encodeController] autorelease];
        navigationController.navigationBarHidden = YES;
        navigationController.toolbarHidden = NO;
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;

        RootContentController *rootContentController = [UIApplication sharedRootContentController];
        [rootContentController.trackListPopoverController dismissPopoverAnimated:YES];
        [rootContentController popoverControllerDidDismissPopover:rootContentController.trackListPopoverController];

        [rootContentController presentViewController:navigationController animated:YES completion: nil];
    }

    return viewController;
}

#pragma mark - Table view callbacks

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectGetHeight([UINib containerViewBoundsForNibNamed:@"TrackListTableViewCell"]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    TrackListTableViewCell *cell = [TrackListTableViewCell cellForTableView:tableView fromNib:self.tableViewCellFromNib];

    cell.selectedBackgroundView = [[[UIView alloc] init] autorelease];
    cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];

    id item = [self.items objectAtIndex:(NSUInteger)indexPath.row];

    if ([item isKindOfClass:[LMResource class]]) {

        cell.controller = self;

        LMResource *resource = (LMResource *) item;
        cell.name.text = resource.name;
        cell.path.text   = [resource tableViewCellPath];

        resource.enabled = nil != [rootContentController.trackControllers objectForKey:resource.path];
        [cell.enabledSwitch setOn:resource.enabled animated:NO];
        cell.enabledSwitch.hidden = NO;

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;

    } else {

        cell.name.text = ([item isKindOfClass:[NSString class]]) ? item : ((LMCategory *)item).name;

        cell.path.text   = @"";
        cell.enabledSwitch.hidden = YES;

        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSUInteger row = (NSUInteger)indexPath.row;
    if (-1 == self.nestingLevel && [[self.items objectAtIndex:row] isEqualToString:kPublicTracks]) {

        dispatch_async([GenomeManager sharedGenomeManager].dataRetrievalQueue, ^{

            NSError *error = nil;
            if (![[GenomeManager sharedGenomeManager] loadTrackMenuWithGenomeName:[GenomeManager sharedGenomeManager].currentGenomeName error:&error]) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[IGVHelpful sharedIGVHelpful] presentError:error];
                });

                return;
            }

            NSDictionary *currentTrackMenu = [[GenomeManager sharedGenomeManager] currentTrackMenu];

            NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:[currentTrackMenu objectForKey:kLMCategoryItemsKey]];

            if ([[GenomeManager sharedGenomeManager] encodeFileExistsForGenomeName:[GenomeManager sharedGenomeManager].currentGenomeName]) {
                [mutableArray addObject:kENCODELabel];
            }

            TrackListController *trackListController = [[[TrackListController alloc] initWithList:mutableArray
                                                           nestingLevel:(1 + self.nestingLevel)
                                                                nibName:nil
                                                                 bundle:nil] autorelease];

            dispatch_async(dispatch_get_main_queue(), ^{

                trackListController.preferredContentSize = self.preferredContentSize;

                UIBarButtonItem *backButton = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
                [self.navigationItem setBackBarButtonItem:backButton];

                trackListController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;

                [self.navigationController pushViewController:trackListController animated:YES];

                [self.tableView reloadData];
            });

        });

    } else {

        UIViewController *viewController = [self controllerForTableViewItem:[self.items objectAtIndex:row]];
        if (viewController) {

            viewController.preferredContentSize = self.preferredContentSize;

            UIBarButtonItem *backButton = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
            [self.navigationItem setBackBarButtonItem:backButton];

            viewController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;

            [self.navigationController pushViewController:viewController animated:YES];
        }

    }


}

#pragma mark - Instance Methods

- (void)enableTrackWithTrackListTableViewCell:(TrackListTableViewCell *)trackListTableViewCell {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    [rootContentController.trackListPopoverController dismissPopoverAnimated:YES];

    // NOTE: Call popoverControllerDelegate method explicitly since it is not called when we dismiss the popoverController programatically
    [rootContentController popoverControllerDidDismissPopover:rootContentController.trackListPopoverController];

    NSIndexPath *indexPath = [self.tableView indexPathForCell:trackListTableViewCell];

    id item = [self.items objectAtIndex:(NSUInteger)indexPath.row];
    if ([item isKindOfClass:[LMResource class]]) {

        LMResource *resource = (LMResource *)item;
        resource.enabled = trackListTableViewCell.enabledSwitch.on;

        if (!resource.enabled) {

            [rootContentController discardTrackWithResource:resource];
        } else {

            [rootContentController enableTracksWithResources:[NSArray arrayWithObject:resource] appLaunchLocusCentroid:nil];
        }
    }

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Nib Name

- (UINib *)tableViewCellFromNib {

    if (nil == tableViewCellFromNib) {
        self.tableViewCellFromNib = [UINib nibWithNibName:@"TrackListTableViewCell" bundle:nil];
    }

    return tableViewCellFromNib;
}

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}
@end
