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
// Created by turner on 1/17/14.
//

#import "ENCODETableViewCell.h"
#import "Logging.h"
#import "ENCODEViewController.h"

@implementation ENCODETableViewCell

@synthesize cell = _cell;
@synthesize dataType = _dataType;
@synthesize antibody = _antibody;
@synthesize view = _view;
@synthesize replicate = _replicate;
@synthesize type = _type;
@synthesize lab = _lab;
@synthesize hub = _hub;
@synthesize trackSelectionSwitch = _trackSelectionSwitch;
@synthesize controller = _controller;
@synthesize tableView = _tableView;

- (void)dealloc {

    self.cell = nil;
    self.dataType = nil;
    self.antibody = nil;
    self.view = nil;
    self.replicate = nil;
    self.type = nil;
    self.lab = nil;
    self.hub = nil;

    self.trackSelectionSwitch = nil;
    self.controller = nil;
    self.tableView = nil;

    [super dealloc];

}

- (void)awakeFromNib {

    self.trackSelectionSwitch.transform = CGAffineTransformConcat(self.trackSelectionSwitch.transform, CGAffineTransformMakeScale(.75, .75));
}

- (IBAction) toggleTrackSelectionSwitch:(UISwitch *)trackSelectionSwitch {

    [self.controller encodeTableViewCell:self trackSelectionToggle:trackSelectionSwitch.on];
}

//- (void)drawRect:(CGRect)rect {
//
//    [super drawRect:rect];
//
//    [self.trackSelectionSwitch setOnTintColor:[UIColor colorWithRed:0.000 green:0.478 blue:0.882 alpha:1.0]];
//}

+ (id)cellForTableView:(UITableView *)tableView fromNib:(UINib *)nib {
    ENCODETableViewCell *encodeTableViewCell = (ENCODETableViewCell *)[super cellForTableView:tableView fromNib:nib];
    return encodeTableViewCell;
}

@end
