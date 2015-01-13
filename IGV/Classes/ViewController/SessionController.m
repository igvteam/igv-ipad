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
//  SessionController.m
//  IGV
//
//  Created by turner on 4/3/14.
//
//

#import "SessionController.h"
#import "SessionListTableViewCell.h"
#import "PListPersistence.h"
#import "GenomeManager.h"
#import "IGVContext.h"
#import "IGVAppDelegate.h"
#import "UIApplication+IGVApplication.h"
#import "LMResource.h"
#import "NSMutableDictionary+TrackController.h"
#import "UIColor+Array.h"
#import "TrackContainerScrollView.h"
#import "GenomeNameListController.h"
#import "SessionSaveController.h"
#import "Logging.h"

@interface SessionController ()
@property(nonatomic, retain) NSMutableArray *items;
@property(nonatomic, retain) IBOutlet UIButton *loadButton;
@property(nonatomic, copy) NSString *currentSessionName;
@property(nonatomic, retain) PListPersistence *sessionPersistence;
- (void)genomeSelectionDidChangeWithNotification:(NSNotification *)notification;
- (void)displayNoUserDefinedGenomeWithName:name;
- (IBAction)unwindControllerWithSeque:(UIStoryboardSegue *)segue;
@end

@implementation SessionController

@synthesize items = _items;
@synthesize loadButton = _loadButton;
@synthesize currentSessionName = _currentSessionName;
@synthesize sessionPersistence = _sessionPersistence;

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:GenomeSelectionDidChangeNotification object:nil];
    self.items = nil;
    self.loadButton = nil;
    self.currentSessionName = nil;
    self.sessionPersistence = nil;

    [super dealloc];
}

- (void)awakeFromNib {

    self.sessionPersistence = [[[PListPersistence alloc] init] autorelease];
    BOOL success = [self.sessionPersistence usePListPrefix:@"defaultSession"];

    self.items = [NSMutableArray arrayWithArray:[[self.sessionPersistence plistDictionary] allKeys]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeSelectionDidChangeWithNotification:) name:GenomeSelectionDidChangeNotification object:nil];

}

#pragma mark - Respond to genome change

- (void)genomeSelectionDidChangeWithNotification:(NSNotification *)notification {
    self.currentSessionName = nil;
}

- (void)displayNoUserDefinedGenomeWithName:(NSString *)name {

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ERROR"
                                                     message:[NSString stringWithFormat:@"No User Defined Genome Named %@", name]
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil] autorelease];

    [alert show];

}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    SessionListTableViewCell *sessionListTableViewCell = [tableView dequeueReusableCellWithIdentifier:@"SessionListReuseIdentifier" forIndexPath:indexPath];
    sessionListTableViewCell.nameLabel.text = [self.items objectAtIndex:(NSUInteger)indexPath.row];

    sessionListTableViewCell.loadButton.hidden = self.isEditing ? YES : NO;

    return sessionListTableViewCell;
}

#pragma mark - Table view edit methods

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    SessionListTableViewCell *sessionListTableViewCell = (SessionListTableViewCell *) [tableView cellForRowAtIndexPath:indexPath];
    sessionListTableViewCell.loadButton.hidden = self.isEditing ? YES : NO;

    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {

        id key = [self.items objectAtIndex:(NSUInteger) indexPath.row];
        [self.items removeObjectAtIndex:(NSUInteger)indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

        NSMutableDictionary *dictionary = [self.sessionPersistence plistDictionary];
        [dictionary removeObjectForKey:key];
        [self.sessionPersistence writePListDictionary:dictionary];
        [self.tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {

    id item = [[self.items objectAtIndex:(NSUInteger)sourceIndexPath.row] retain];

    [self.items removeObjectAtIndex:(NSUInteger)sourceIndexPath.row];
    [self.items insertObject:item atIndex:(NSUInteger)destinationIndexPath.row];

    [item release];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - SessionListTableViewCell callback

- (void)loadSessionWithTableViewCell:(SessionListTableViewCell *)tableViewCell {

    NSMutableDictionary *plistDictionary = [self.sessionPersistence plistDictionary];
    NSDictionary *sessionDictionary = [plistDictionary objectForKey:tableViewCell.nameLabel.text];

    if (![[[GenomeManager sharedGenomeManager] genomeStubs] objectForKey:[sessionDictionary objectForKey:@"genome"]]) {

        [self displayNoUserDefinedGenomeWithName:[sessionDictionary objectForKey:@"genome"]];
        return;
    }

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController unwindViewControllerStackWithPopoverController:rootContentController.sessionListPopoverController];
    [rootContentController.sessionListPopoverController dismissPopoverAnimated:YES];
    [rootContentController popoverControllerDidDismissPopover:rootContentController.sessionListPopoverController];

    [[UIApplication sharedIGVAppDelegate] disableUserInteraction];

    self.currentSessionName = tableViewCell.nameLabel.text;

    [UIApplication sharedIGVAppDelegate].commandDictionary = [NSMutableDictionary dictionary];
    [[UIApplication sharedIGVAppDelegate].commandDictionary setObject:[sessionDictionary objectForKey:@"genome"] forKey:@"genome"];
    [[UIApplication sharedIGVAppDelegate].commandDictionary setObject:[sessionDictionary objectForKey:@"locus"] forKey:@"locus"];
    NSArray *tracks = [sessionDictionary objectForKey:@"tracks"];

    if ([tracks count] > 0) {

        NSMutableArray *resources = [NSMutableArray array];
        for (NSDictionary *track in tracks) {

            LMResource *resource = [LMResource resourceWithName:[track objectForKey:@"name"] filePath:[track objectForKey:@"path"] indexPath:[track objectForKey:@"indexPath"]];
            resource.color = ([track objectForKey:@"color"]) ? [UIColor colorWithRGBArray:[track objectForKey:@"color"]] : nil;
            [resources addObject:resource];
        }

        [[UIApplication sharedIGVAppDelegate].commandDictionary setObject:resources forKey:kCommandResourceKey];
    }

    [rootContentController.trackControllers removeAllTracks];

    // This allows the popover to retract immediately. Ish.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DidLaunchApplicationViaURLNotification object:nil];

    });



}

#pragma mark - UIStoryboard methods

- (IBAction)unwindControllerWithSeque:(UIStoryboardSegue *)segue {

    if ([@"UnwindSaveSessionControllerWithDone" isEqualToString:segue.identifier]) {

        SessionSaveController *sessionSaveController = segue.sourceViewController;
        if (nil == sessionSaveController.saveSessionTextField.text || [@"" isEqualToString:sessionSaveController.saveSessionTextField.text]) {
            return;
        }

        NSMutableDictionary *session = [NSMutableDictionary dictionary];
        [session setObject:[GenomeManager sharedGenomeManager].currentGenomeName forKey:@"genome"];
        [session setObject:[[IGVContext sharedIGVContext] currentLocus] forKey:@"locus"];

        NSMutableArray *tracks = [NSMutableArray array];

        RootContentController *rootContentController = [UIApplication sharedRootContentController];
        NSArray *tracksInScreenLayoutOrder = [rootContentController.trackContainerScrollView tracksInScreenLayoutOrder];
        for (TrackView * trackView in tracksInScreenLayoutOrder) {

            NSMutableDictionary *track = [NSMutableDictionary dictionary];
            NSArray *rgb = nil;
            if (nil != trackView.resource.color) {

                CGFloat r, g, b, a;
                [trackView.resource.color getRed:&r green:&g blue:&b alpha:&a];
                rgb = [NSArray arrayWithObjects:[NSNumber numberWithFloat:r], [NSNumber numberWithFloat:g], [NSNumber numberWithFloat:b], nil];
                [track setObject:rgb forKey:@"color"];
            }

            [track setObject:trackView.trackLabel.text forKey:@"name"];
            [track setObject:trackView.resource.filePath forKey:@"path"];
            if (trackView.resource.indexPath) {
                [track setObject:trackView.resource.indexPath forKey:@"indexPath"];
            }
            [track setObject:[NSNumber numberWithUnsignedInteger:[tracksInScreenLayoutOrder indexOfObject:trackView]] forKey:@"index"];

            [tracks insertObject:track atIndex:0];
        }

        [session setObject:tracks forKey:@"tracks"];

        NSMutableDictionary *plistPersistenceDictionary = [self.sessionPersistence plistDictionary];
        [plistPersistenceDictionary setObject:session forKey:sessionSaveController.saveSessionTextField.text];
        [self.sessionPersistence writePListDictionary:plistPersistenceDictionary];

        if (nil == self.currentSessionName || ![self.currentSessionName isEqualToString:sessionSaveController.saveSessionTextField.text]) {

            self.currentSessionName = sessionSaveController.saveSessionTextField.text;
            [self.items addObject:self.currentSessionName];
            [self.tableView reloadData];
        }

    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    SessionSaveController *sessionSaveController = segue.destinationViewController;
    sessionSaveController.preferredContentSize = self.preferredContentSize;
    sessionSaveController.currentSessionName = self.currentSessionName;
}

@end
