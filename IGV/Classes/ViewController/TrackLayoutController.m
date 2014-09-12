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
//  TrackLayoutController.m
//  IGV
//
//  Created by Douglass Turner on 3/7/13.
//
//

#import "TrackLayoutController.h"
#import "TrackView.h"
#import "RootContentController.h"
#import "TrackContainerScrollView.h"
#import "FileListTableViewCell.h"
#import "TrackLayoutTableViewCell.h"
#import "UINib-View.h"
#import "UIApplication+IGVApplication.h"

@interface TrackLayoutController ()
@property(nonatomic, retain) UINib *tableViewCellFromNib;
@end

@implementation TrackLayoutController

@synthesize inputOrder;
@synthesize outputOrder;
@synthesize tableViewCellFromNib;

- (void)dealloc {

    self.inputOrder = nil;
    self.outputOrder = nil;
    self.tableViewCellFromNib = nil;

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    self.inputOrder  = [rootContentController.trackContainerScrollView tracksInScreenLayoutOrder];
    self.outputOrder = [NSMutableArray arrayWithArray:self.inputOrder];
    [self.tableView reloadData];

    [super setEditing:YES animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {

    [super setEditing:editing animated:animated];

    if (editing) {
        return;
    }

    if (self.isEditing) {
        return;
    }

    [self performSegueWithIdentifier:@"UnwindTrackLayoutControllerWithDone" sender:self];

}

#pragma mark - UITableViewController Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectGetHeight([UINib containerViewBoundsForNibNamed:@"TrackLayoutTableViewCell"]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.outputOrder count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    TrackLayoutTableViewCell *cell = [TrackLayoutTableViewCell cellForTableView:tableView fromNib:self.tableViewCellFromNib];

    TrackView *track = [self.outputOrder objectAtIndex:(NSUInteger) indexPath.row];
    cell.trackLabel.text = track.trackLabel.text;

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {

    TrackView *track = [[self.outputOrder objectAtIndex:(NSUInteger)sourceIndexPath.row] retain];

    [self.outputOrder removeObjectAtIndex:(NSUInteger)sourceIndexPath.row];
    [self.outputOrder insertObject:track atIndex:(NSUInteger)destinationIndexPath.row];

    [track release];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Nib Name

- (UINib *)tableViewCellFromNib {

    if (nil == tableViewCellFromNib) {
        self.tableViewCellFromNib = [UINib nibWithNibName:@"TrackLayoutTableViewCell" bundle:nil];
    }

    return tableViewCellFromNib;
}

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}

@end
