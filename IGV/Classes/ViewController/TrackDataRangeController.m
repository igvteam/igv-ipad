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
//  TrackDataRangeController.m
//  IGV
//
//  Created by turner on 5/6/14.
//
//

#import "TrackDataRangeController.h"
#import "Logging.h"


@interface TrackDataRangeController ()
- (IBAction)toggleAutoScaleWithSwitch:(UISwitch *)sw;
@end

@implementation TrackDataRangeController

@synthesize maxTextField = _maxTextField;
@synthesize minTextField = _minTextField;
@synthesize max = _max;
@synthesize min = _min;
@synthesize autoScaleSwitch = _autoScaleSwitch;
@synthesize scrim = _scrim;
@synthesize doWigFeatureAutoDataScale = _doWigFeatureAutoDataScale;

- (void)dealloc {

    self.maxTextField = nil;
    self.minTextField = nil;

    self.autoScaleSwitch = nil;
    self.scrim = nil;

    [super dealloc];
}

- (void)viewDidLoad {

    self.maxTextField.text = [NSString stringWithFormat:@"%.3f", self.max];
    self.minTextField.text = [NSString stringWithFormat:@"%.3f", self.min];

    self.autoScaleSwitch.on = self.doWigFeatureAutoDataScale;
    self.scrim.alpha = (self.autoScaleSwitch.on) ? 0.75 : 0;
}

- (IBAction)toggleAutoScaleWithSwitch:(UISwitch *)sw {

    self.scrim.alpha = (sw.on) ? 0.75 : 0;
    self.doWigFeatureAutoDataScale = (sw.on) ? YES : NO;
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    ALog(@"%@", textField.text);
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    self.max = [self.maxTextField.text floatValue];
    self.min = [self.minTextField.text floatValue];

    [self performSegueWithIdentifier:@"UnwindTrackDataRangeControllerWithDone" sender:self];
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    self.max = [self.maxTextField.text floatValue];
    self.min = [self.minTextField.text floatValue];

    ALog(@"%@ from %@ to %@", [self class], [segue.sourceViewController class], [segue.destinationViewController class]);
}

@end
