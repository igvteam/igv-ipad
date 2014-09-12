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
//  GenomeNameListController.m
//  IGV
//
//  Created by turner on 5/12/14.
//
//

#import "GenomeNameListController.h"
#import "Logging.h"
#import "GenomeManager.h"
#import "IGVHelpful.h"
#import "ChromosomeListController.h"
#import "PListPersistence.h"
#import "UserDefinedGenomeController.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"

NSString *const GenomeSelectionDidChangeNotification = @"GenomeSelectionDidChangeNotification";

NSInteger kGenomeNameLabelTag = 44;

@interface GenomeNameListController ()
- (UITableViewCell *)configureTableViewCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath;
- (void)displayInvalidUserDefinedGenomePath:(NSString *)path;
- (IBAction)unwindControllerWithSeque:(UIStoryboardSegue *)segue;
@end

@implementation GenomeNameListController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewWillAppear:(BOOL)animated {

    self.tableView.hidden = YES;

    [[GenomeManager sharedGenomeManager] loadGenomeWithContinuation:^(NSString *selectedGenomeName, NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{

            if (error) {

                [[IGVHelpful sharedIGVHelpful] presentError:error];
            } else {

                [self.tableView reloadData];
                self.tableView.hidden = NO;

                [self.tableView selectRowAtIndexPath:[[GenomeManager sharedGenomeManager] indexPathWithCurrentGenomeName]
                                            animated:NO
                                      scrollPosition:UITableViewScrollPositionNone];
            }
        });
    }];

}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[GenomeManager sharedGenomeManager] genomeNames] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GenomeListReuseIdentifier" forIndexPath:indexPath];

    return [self configureTableViewCell:cell indexPath:indexPath];
}

- (UITableViewCell *)configureTableViewCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {

    cell.textLabel.highlightedTextColor = [UIColor whiteColor];

    UILabel *label = (UILabel *) [cell.contentView viewWithTag:kGenomeNameLabelTag];
    label.text = [[GenomeManager sharedGenomeManager] tableViewLabelTextWithIndex:indexPath.row];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *genomeName = [[[GenomeManager sharedGenomeManager] genomeNames] objectAtIndex:(NSUInteger)indexPath.row];
    if ([genomeName isEqualToString:[GenomeManager sharedGenomeManager].currentGenomeName]) {

        return NO;
    } else {

        return [[GenomeManager sharedGenomeManager] isUserDefinedGenomeAtIndex:indexPath.row];
    }

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {

        [[GenomeManager sharedGenomeManager] deleteUserDefinedGenomeAtIndex:indexPath.row continuation:^(void) {

            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];

        }];

    }
}

#pragma mark - UIStoryboardSegue Methods

- (IBAction)unwindControllerWithSeque:(UIStoryboardSegue *)segue {

    if ([@"UnwindUserDefinedGenomeControllerWithSave" isEqualToString:segue.identifier]) {

        UserDefinedGenomeController *userDefinedGenomeController = segue.sourceViewController;
        if (nil == userDefinedGenomeController.userDefinedGenome) {
            return;
        }

        NSString *userDefinedGenomeName = [[userDefinedGenomeController.userDefinedGenome allKeys] firstObject];
        NSDictionary *userDefinedGenomePayload = [userDefinedGenomeController.userDefinedGenome objectForKey:userDefinedGenomeName];

        for (id key in [userDefinedGenomePayload allKeys]) {

            HttpResponse *httpResponse  = [URLDataLoader loadHeaderSynchronousWithPath:[userDefinedGenomePayload objectForKey:key]];
            if (nil != httpResponse.error) {
                [self displayInvalidUserDefinedGenomePath:[userDefinedGenomePayload objectForKey:key]];
                return;
            }
        }

        NSMutableDictionary *userDefinedGenomesPersistenceDictionary = [[GenomeManager sharedGenomeManager].userDefinedGenomePersistence plistDictionary];

        [userDefinedGenomesPersistenceDictionary setObject:userDefinedGenomePayload forKey:userDefinedGenomeName];
        [[GenomeManager sharedGenomeManager].userDefinedGenomePersistence writePListDictionary:userDefinedGenomesPersistenceDictionary];

    }

}

- (void)displayInvalidUserDefinedGenomePath:(NSString *)path {

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:[NSString stringWithFormat:@"Invalid path %@", path]
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil] autorelease];

    [alert show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([@"ChromosomeListSegue" isEqualToString:segue.identifier]) {

        UITableViewCell *cell = sender;
        UILabel *label = (UILabel *) [cell.contentView viewWithTag:kGenomeNameLabelTag];

        self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:label.text style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];

        ChromosomeListController *chromosomeListController = segue.destinationViewController;

        NSArray *keys = [[[GenomeManager sharedGenomeManager].genomeStubs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

        chromosomeListController.genomeName = [keys objectAtIndex:(NSUInteger)indexPath.row];

    }

//    if ([@"GenomeAddSegue" isEqualToString:segue.identifier]) {
//
//        ALog(@"Destination controller %@", [segue.destinationViewController class]);
//    }

}

@end
