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
//  TrackListTableViewCell.m
//  IGV
//
//  Created by Douglass Turner on 2/18/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "TrackListTableViewCell.h"
#import "TrackListController.h"

@interface TrackListTableViewCell ()
- (IBAction)didSetSwitch:(UISwitch *)sw;
@end

@implementation TrackListTableViewCell

@synthesize name;
@synthesize path;
@synthesize enabledSwitch;
@synthesize controller;

- (void)dealloc {

    self.name = nil;
    self.path = nil;
    self.enabledSwitch = nil;
    self.controller = nil;

    [super dealloc];
}

- (void)awakeFromNib {

    [self.enabledSwitch addTarget:self action:@selector(didSetSwitch:) forControlEvents:UIControlEventValueChanged];

    self.controller = nil;
}

- (IBAction)didSetSwitch: (UISwitch *)sw {
    [self.controller enableTrackWithTrackListTableViewCell:self];
}

+ (id)cellForTableView:(UITableView *)tableView fromNib:(UINib *)nib {

    TrackListTableViewCell *cell = (TrackListTableViewCell *)[super cellForTableView:tableView fromNib:nib];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType  = UITableViewCellAccessoryNone;

    return cell;
}

@end
