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
//  SessionListTableViewCell.m
//  IGV
//
//  Created by turner on 4/4/14.
//
//

#import "SessionListTableViewCell.h"
#import "Logging.h"
#import "SessionController.h"

@interface SessionListTableViewCell ()
@property(nonatomic, assign) IBOutlet SessionController *controller;
- (IBAction)loadButtonHandler:(UIButton *)button;
@end

@implementation SessionListTableViewCell

@synthesize loadButton = _loadButton;
@synthesize nameLabel = _nameLabel;
@synthesize controller = _controller;

- (void)dealloc {

    self.nameLabel = nil;
    self.loadButton = nil;
    self.controller = nil;

    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {

    self.loadButton.layer.cornerRadius = 4;
    self.loadButton.layer.borderWidth = 1;
    self.loadButton.layer.borderColor = self.loadButton.currentTitleColor.CGColor;
}

- (IBAction)loadButtonHandler:(UIButton *)button {

    [self.controller loadSessionWithTableViewCell:self];

}

@end
