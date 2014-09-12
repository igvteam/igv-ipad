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
// Created by turner on 12/17/13.
//

#import "TrackDelegate.h"
#import "TrackView.h"
#import "BarChartRenderer.h"
#import "Logging.h"

NSString *const TrackDidSquishExpandNotification = @"TrackDidSquishExpandNotification";
NSString *const TrackDelegateBasisSelectionNotification = @"TrackDelegateBasisSelectionNotification";

NSTimeInterval const kSquishAnimationDuration = (1.0/2.0);
NSTimeInterval const kSquishAnimationDelay = 0.0;

@implementation TrackDelegate

@synthesize track = _track;

- (void)dealloc {

    self.track = nil;

    [super dealloc];
}

- (void)animateTrack:(TrackView *)track toTargetHeight:(CGFloat)toTargetHeight {

    CGRect targetFrame = track.frame;
    targetFrame.size.height = toTargetHeight;

    [UIView animateWithDuration:kSquishAnimationDuration
                          delay:kSquishAnimationDelay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                         track.frame = targetFrame;
                     }
                     completion:^(BOOL finished){
                         [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidSquishExpandNotification object:track];
                     }];
}

- (void)squishExpandTrack:(TrackView *)track {

    CGRect expandedFrame = track.frame;
    expandedFrame.size.height = [track expandedTrackHeight];

    CGRect squishFrame = track.frame;
    squishFrame.size.height = [track squishedTrackHeight];

    [UIView animateWithDuration:kSquishAnimationDuration
                          delay:kSquishAnimationDelay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                         track.frame = (track.isSquished) ? expandedFrame : squishFrame;
                     }
                     completion:^(BOOL finished){

                         track.isSquished = !(track.isSquished);
                         [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidSquishExpandNotification object:track];
                     }];
}

@end