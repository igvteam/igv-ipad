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
//  MyTracksController.m
//  IGV
//
//  Created by Douglass Turner on 2/2/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "MyTracksController.h"
#import "FileListItem.h"
#import "RootContentController.h"
#import "FileListTableViewCell.h"
#import "UINib-View.h"
#import "NSUserDefaults+LocusFileURL.h"
#import "LMResource.h"
#import "UIApplication+IGVApplication.h"
#import "GenomeManager.h"
#import "GenomeNameListController.h"
#import "IGVHelpful.h"

@interface MyTracksController ()
@property(nonatomic, retain) UINib *tableViewCellFromNib;
@property(nonatomic, retain) NSMutableDictionary *urlList;
- (void)presentFileURLDialogWithBarButtonItem:(UIBarButtonItem *)barButtonItem;
@end

@implementation MyTracksController

@synthesize tableViewCellFromNib = _tableViewCellFromNib;
@synthesize urlList = _urlList;

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:GenomeSelectionDidChangeNotification object:nil];

    self.tableViewCellFromNib = nil;
    self.urlList = nil;

    [super dealloc];
}

#pragma mark - View lifecycle

-(void)viewDidLoad {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeSelectionDidChangeWithNotification:) name:GenomeSelectionDidChangeNotification object:nil];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Add Track"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(presentFileURLDialogWithBarButtonItem:)] autorelease];

}

- (void)viewWillAppear:(BOOL)animated {

    self.urlList = nil;

    NSArray *filesListDefaults = [[NSUserDefaults standardUserDefaults] arrayForKey:kFilesListDefaults];
    if (nil == filesListDefaults) {
        return;
    }

    for (NSDictionary *fileListDefaultsItem in filesListDefaults) {

        NSString *genome    = [FileListItem genomeWithFileListDefaultsItem:fileListDefaultsItem];
        NSString *filePath = [FileListItem filePathWithFileListDefaultsItem:fileListDefaultsItem];
        NSString *indexPath = [FileListItem indexPathWithFileListDefaultsItem:fileListDefaultsItem];
        NSString *label     = [FileListItem labelWithFileListDefaultsItem:fileListDefaultsItem];

        if (nil == [self.urlList objectForKey:genome]) {
            [self.urlList setObject:[NSMutableArray array] forKey:genome];
        }

        NSMutableArray *fileListItems = [self.urlList objectForKey:genome];
        [fileListItems addObject:[[[FileListItem alloc] initWithFilePath:filePath label:label genome:genome indexPath:indexPath] autorelease]];

    }

    [self.tableView reloadData];
}

- (NSMutableDictionary *)urlList {

    if (nil == _urlList) {
        self.urlList = [NSMutableDictionary dictionary];
    }

    return _urlList;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - Table view callbacks

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectGetHeight([UINib containerViewBoundsForNibNamed:@"FileListTableViewCell"]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray *fileListItems = [self.urlList objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];
    return [fileListItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    FileListTableViewCell *fileListTableViewCell = [FileListTableViewCell cellForTableView:tableView fromNib:self.tableViewCellFromNib];
    fileListTableViewCell.controller = self;

    NSMutableArray *fileListItems = [self.urlList objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];
    FileListItem *fileListItem = [fileListItems objectAtIndex:(NSUInteger)indexPath.row];

    fileListTableViewCell.label.text = [fileListItem tableViewCellLabel];
    fileListTableViewCell.path.text = [fileListItem tableViewCellURL];

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    fileListItem.enabled = nil != [rootContentController.trackControllers objectForKey:fileListItem.filePath];
    [fileListTableViewCell.enabledSwitch setOn:fileListItem.enabled animated:NO];
    fileListTableViewCell.enabledSwitch.hidden = self.isEditing ? YES : NO;


    return fileListTableViewCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    FileListTableViewCell *fileListTableViewCell = (FileListTableViewCell *) [tableView cellForRowAtIndexPath:indexPath];
    fileListTableViewCell.enabledSwitch.hidden = self.isEditing ? YES : NO;

    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {

        NSMutableArray *fileListItems = [self.urlList objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];
        FileListItem *fileListItem = [fileListItems objectAtIndex:(NSUInteger) indexPath.row];

        if (fileListItem.enabled) {

            RootContentController *rootContentController = [UIApplication sharedRootContentController];
            [rootContentController discardTrackWithResource:[LMResource resourceWithFileListItem:fileListItem]];
        }

        [[NSUserDefaults standardUserDefaults] removeFileListItem:fileListItem forKey:kFilesListDefaults];
        [fileListItems removeObjectAtIndex:(NSUInteger)indexPath.row];

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Instance Methods

- (IBAction)enableTrackWithFileListTableViewCell:(FileListTableViewCell *)fileListTableViewCell {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    [rootContentController.trackListPopoverController dismissPopoverAnimated:YES];

    // NOTE: Call popoverControllerDelegate method explicitly since it is not called when we dismiss the popoverController programatically
    [rootContentController popoverControllerDidDismissPopover:rootContentController.trackListPopoverController];

    NSIndexPath *indexPath = [self.tableView indexPathForCell:fileListTableViewCell];
    NSMutableArray *fileListItems = [self.urlList objectForKey:[GenomeManager sharedGenomeManager].currentGenomeName];
    FileListItem *fileListItem = [fileListItems objectAtIndex:(NSUInteger) indexPath.row];

    fileListItem.enabled = fileListTableViewCell.enabledSwitch.on;

    if (!fileListItem.enabled) {

        [rootContentController discardTrackWithResource:[LMResource resourceWithFileListItem:fileListItem]];
    } else {

        NSString *blurb = nil;
        if (![IGVHelpful isUsablePath:fileListItem.filePath
                                blurb:&blurb]) {

            fileListTableViewCell.enabledSwitch.on = NO;

            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                                 message:blurb
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] autorelease];

            [alertView show];

        } else {

            [rootContentController enableTracksWithResources:[NSArray arrayWithObject:[LMResource resourceWithFileListItem:fileListItem]]
                                      appLaunchLocusCentroid:nil];

        }

    }

}

#pragma mark - FileURLDialogController callbacks

- (void)presentFileURLDialogWithBarButtonItem:(UIBarButtonItem *)barButtonItem {

    UINavigationController *navigationController = [[[UINib nibWithNibName:@"FileURLDialogNavigationBar" bundle:nil] instantiateWithOwner:nil options:nil] objectAtIndex:0];
    navigationController.preferredContentSize = self.preferredContentSize;
    navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;

    FileURLDialogController *fileURLDialogController = (FileURLDialogController *) navigationController.topViewController;
    fileURLDialogController.preferredContentSize = self.preferredContentSize;
    fileURLDialogController.delegate = self;

    [self presentViewController:navigationController animated:YES completion:nil];

}

- (void)fileURLDialogController:(FileURLDialogController *)fileURLDialogController addFileListItem:(FileListItem *)fileListItem {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    [rootContentController.trackListPopoverController dismissPopoverAnimated:YES];

    // NOTE: Call popoverControllerDelegate method explicitly since it is not called when we dismiss the popoverController programatically
    [rootContentController popoverControllerDidDismissPopover:rootContentController.trackListPopoverController];

    if (nil == fileListItem) {
        return;
    }

    fileListItem.enabled = YES;

    // Automatically add to user defaults. MyTracks will present this fileListItem.
    [[NSUserDefaults standardUserDefaults] addFileListItem:fileListItem forKey:kFilesListDefaults];
    [rootContentController enableTracksWithResources:[NSArray arrayWithObject:[LMResource resourceWithFileListItem:fileListItem]] appLaunchLocusCentroid:nil];

    [self.tableView reloadData];
}

#pragma mark - Notification Callbacks

- (void)genomeSelectionDidChangeWithNotification:(NSNotification *)notification {
    [self.tableView reloadData];
}

#pragma mark - Nib Name

- (UINib *)tableViewCellFromNib {

    if (nil == _tableViewCellFromNib) {
        self.tableViewCellFromNib = [UINib nibWithNibName:@"FileListTableViewCell" bundle:nil];
    }

    return _tableViewCellFromNib;
}

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}

@end
