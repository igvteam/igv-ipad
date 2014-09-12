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
// Created by turner on 6/27/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "UINib-View.h"
#import "RootContentController.h"
#import "UINavigationItem+RootContentController.h"
#import "ZoomSlider.h"
#import "Logging.h"


@implementation UINavigationItem (RootContentController)

- (void)configureWithRootContentController:(RootContentController *)rootContentController {

    // Genomes | Tracks | Loci
    UISegmentedControl *segmentedControl = (UISegmentedControl *)[UINib containerViewForNibNamed:@"LeftBarButtonItemCustomView"];
    [segmentedControl addTarget:rootContentController action:@selector(segmentedControlHandlerWithSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.autoresizingMask = UIViewAutoresizingNone;
    UIBarButtonItem *leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithCustomView:segmentedControl] autorelease];
    self.leftBarButtonItem = leftBarButtonItem;


    // Goto textField
    NSString *textFieldNibName =  (2.0 == [UIScreen mainScreen].scale) ? @"TitleView_retina_display" : @"TitleView";

    UITextField *textField = (UITextField *)[UINib containerViewForNibNamed:textFieldNibName];
    textField.delegate = rootContentController;
    rootContentController.locusTextField = textField;
    self.titleView = textField;
    self.titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;


    // Zoom Widget
    ZoomSlider *zoomSlider = (ZoomSlider *)[UINib containerViewForNibNamed:@"RightBarButtonItemCustomView"];
    [zoomSlider addTarget:rootContentController action:@selector(zoomSliderValueChanged) forControlEvents:UIControlEventValueChanged];

    zoomSlider.minimumValue = 0;
//    zoomSlider.maximumValue = 10;

    // NOTE: Using 20 instead of 10 allows greater magnification to allow viewing of individual nucleotides
    zoomSlider.maximumValue = 20;

//    zoomSlider.continuous = YES;
    zoomSlider.continuous = NO;

    zoomSlider.value = 0.5 * (zoomSlider.maximumValue + zoomSlider.minimumValue);

    zoomSlider.autoresizingMask = UIViewAutoresizingNone;
    UIBarButtonItem *rightBarButtonItem  = [[[UIBarButtonItem alloc] initWithCustomView:zoomSlider] autorelease];
    self.rightBarButtonItem = rightBarButtonItem;

}

-(UISegmentedControl *)genomesTracksLociSegmentedControl {
    return (UISegmentedControl *)self.leftBarButtonItem.customView;
}

-(UITextField *)gotoTextField {
    return (UITextField *)self.titleView;
}

-(ZoomSlider *)zoomSlider {
    return (ZoomSlider *)self.rightBarButtonItem.customView;
}

@end