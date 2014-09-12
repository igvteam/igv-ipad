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
//  TrackContainerScrollView.m
//  IGV
//
//  Created by Douglass Turner on 3/30/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "TrackContainerScrollView.h"
#import "TrackView.h"
#import "TrackController.h"
#import "Logging.h"
#import "UILabel+TrackView.h"
#import "UIApplication+IGVApplication.h"
#import "TrackDelegate.h"
#import "NSMutableDictionary+TrackController.h"

NSTimeInterval const kTrackLayoutAnimationDuration = (1.0/2.0);
NSTimeInterval const kTrackLayoutAnimationDelay = 0.0;

@interface TrackContainerScrollView ()
@property(nonatomic) NSInteger currentTrackTag;

- (void)trackDidSquishExpandWithNotification:(NSNotification *)notification;
- (CGSize)trackListBBoxSize;
- (BOOL)trackOrderUnchangedWithOutputOrder:(NSArray *)outputOrder inputOrder:(NSArray *)inputOrder;
@end

@implementation TrackContainerScrollView
@synthesize trackLabelsAreHidden;
@synthesize currentTrackTag;
@synthesize geneTrack;

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:TrackDidSquishExpandNotification object:nil];
    self.geneTrack = nil;

    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];

    if (nil != self) {
        
        [self initializationHelper];
    }
    
    return self;
}

- (void)awakeFromNib {
    
    [self initializationHelper];
}

- (void)initializationHelper {

    self.trackLabelsAreHidden = NO;
    self.currentTrackTag = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDidSquishExpandWithNotification:) name:TrackDidSquishExpandNotification object:nil];
}

#pragma mark - Track Label Methods

- (void)maintainStationaryTrackLabelsWithRootScrollView:(RootScrollView *)rootScrollView {

    // Maintain track label at fixed position with respect to moving track
    for (TrackView *track in self.subviews) {

        if (nil == track.trackLabel) continue;

        track.trackLabel.frame = [track trackLabelFrameWithScrollViewContentOffset:rootScrollView.contentOffset trackLabelFrame:track.trackLabel.frame];
    }

}

- (void)hideTrackLabels:(BOOL)hide {

    if (!hide && self.trackLabelsAreHidden) {
        return;
    }

    for (TrackView *track in self.subviews) {

        if (nil == track.trackLabel) continue;
        track.trackLabel.hidden = hide;
    }

}

- (void)toggleTrackLabels {

    self.trackLabelsAreHidden = !self.trackLabelsAreHidden;
    [self hideTrackLabels:self.trackLabelsAreHidden];
}

- (NSString *)actionSheetTrackLabelToggleTitle {

    return [NSString stringWithFormat:@"%@ Track Labels", self.trackLabelsAreHidden ? @"Show" : @"Hide"];
}

#pragma mark - Track Methods

- (void)addTrack:(TrackView *)track {

    [self addSubview:track];

    // Position new track below gene track of the gene track is present
    // and has not been repositioned by the user. If the user repositions
    // the gene track self.geneTrack is made nil. The gene track is nolonger
    // maintained at screen top.
    CGRect fr;
    fr = track.frame;
    fr.origin.y += (nil != self.geneTrack) ? CGRectGetHeight(self.geneTrack.bounds) : CGRectGetHeight(CGRectZero);
    track.frame = fr;

    for (TrackView *t in self.subviews) {

        if (track == t) {
            continue;
        }

        if (nil != self.geneTrack && t == self.geneTrack) {
            continue;
        }

        fr = t.frame;
        fr.origin.y += CGRectGetHeight(track.frame);
        t.frame = fr;
    }

    self.contentSize = [self trackListBBoxSize];
//    [IGVMath prettyPrintSize:self.contentSize blurb:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]];

    if (nil == track.trackLabel) return;

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    CGRect trackLabelFrame = track.trackLabel.frame;
    track.trackLabel.frame = [track trackLabelFrameWithScrollViewContentOffset:rootContentController.rootScrollView.contentOffset trackLabelFrame:trackLabelFrame];

}

- (void)discardTrack:(TrackView *)track {

    if ([self.subviews count] > 1) {

        NSMutableArray *displacedTracks = [NSMutableArray array];
        for (TrackView *subview in self.subviews) {

            if (subview == track) continue;

            if (CGRectGetMinY(subview.frame) > CGRectGetMinY(track.frame)) {
                [displacedTracks addObject:subview];
            }
        }

        if ([displacedTracks count] > 0) {

            for (TrackView *displacedTrack in displacedTracks) {

                CGRect frame = displacedTrack.frame;
                frame.origin.y = CGRectGetMinY(displacedTrack.frame) - CGRectGetHeight(track.bounds);
                displacedTrack.frame = frame;
            }
        }
    }

    if (nil != self.geneTrack && track == self.geneTrack) {
        self.geneTrack = nil;
    }

    [track removeFromSuperview];

    self.contentSize = [self trackListBBoxSize];
}

- (void)trackDidSquishExpandWithNotification:(NSNotification *)notification {

    ALog(@"");

    NSArray *tracks = [self tracksInScreenLayoutOrder];

    NSMutableArray *destinationFrames = [NSMutableArray array];

    CGRect north = ((TrackView *) [tracks objectAtIndex:0]).frame;
    [destinationFrames addObject:[NSValue valueWithCGRect:north]];

    for (NSUInteger i = 1; i < [tracks count]; i++) {

        // Position successive south frames abutting below north frame
        CGRect south = ((TrackView *) [tracks objectAtIndex:i]).frame;
        south.origin.y = CGRectGetMaxY(north);

        // Update track frame
        ((TrackView *) [tracks objectAtIndex:i]).frame = south;

        // Accumulate frames for later animation
        [destinationFrames addObject:[NSValue valueWithCGRect:south]];

        north = ((TrackView *) [tracks objectAtIndex:i]).frame;
    }


    CGRect bbox = CGRectZero;
    for (NSValue *value in destinationFrames) bbox = CGRectUnion(bbox, [value CGRectValue]);
    self.contentSize = bbox.size;


    TrackView *trackView = notification.object;
    [trackView.trackLabel layoutTrackLabelWithRenderSurface:[[trackView class] renderSurfaceWithTrackRect:trackView.bounds]];

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.trackControllers renderAllTracks];
}

- (CGSize)trackListBBoxSize {
    
    CGRect bbox = CGRectZero;
    
    for (UIView *v in self.subviews) {
        
        bbox = CGRectUnion(bbox, v.frame);
    }

    return bbox.size;
}

- (TrackView *)trackWithTrackController:(TrackController *)trackController {

    for (UIView *view in self.subviews) {

        if (trackController.track == view) {
            return (TrackView *)view;
        }
    }

    return nil;
}

- (NSArray *)tracksInScreenLayoutOrder {

    return [self.subviews sortedArrayUsingComparator:^(UIView *a, UIView *b) {

        if (CGRectGetMinY(a.frame) == CGRectGetMinY(b.frame)) {

            return NSOrderedSame;
        } else {

            if (CGRectGetMinY(a.frame) < CGRectGetMinY(b.frame)) {

                return NSOrderedAscending;
            }

            if (CGRectGetMinY(a.frame) > CGRectGetMinY(b.frame)) {

                return NSOrderedDescending;
            }

            return NSOrderedSame;
        }
    }];

}

- (void)layoutTracksWithOutputOrder:(NSArray *)outputOrder inputOrder:(NSArray *)inputOrder {

    if ([self trackOrderUnchangedWithOutputOrder:outputOrder inputOrder:inputOrder]) {
        return;
    }

//    for (TrackView *track in outputOrder) {
//
//        ALog(@"out %d %.0f. in %d %.0f. %@.",
//        [outputOrder indexOfObject:track], CGRectGetMinY(track.frame),
//        [inputOrder indexOfObject:track], CGRectGetMinY(track.frame),
//        ([outputOrder indexOfObject:track] == [inputOrder indexOfObject:track]) ? @"UNCHANGED" : @"");
//    }

    if (nil != self.geneTrack) {

        // If gene track is moved we nolonger need to keep track of it and maintain its on screen location
        if ([outputOrder indexOfObject:self.geneTrack] != [inputOrder indexOfObject:self.geneTrack]) {
            self.geneTrack = nil;
        }
    }

    NSMutableArray *destinationFrames = [NSMutableArray array];

    // First track in the list has origin.y = 0
    CGRect fr = ((TrackView *) [outputOrder objectAtIndex:0]).frame;
    fr.origin.y = 0;
    [destinationFrames addObject:[NSValue valueWithCGRect:fr]];

    for (NSUInteger i = 1; i < [outputOrder count]; i++) {

        CGRect north = [[destinationFrames objectAtIndex:(i - 1)] CGRectValue];

        // Position successive south frames abutting below north frame
        CGRect south = ((TrackView *) [outputOrder objectAtIndex:i]).frame;
        south.origin.y = CGRectGetMaxY(north);

        // accumulate frames
        [destinationFrames addObject:[NSValue valueWithCGRect:south]];
    }

//    for (NSValue *value in destinationFrames) {
//
//        ALog(@"%d %.0f", [destinationFrames indexOfObject:value], CGRectGetMinY([value CGRectValue]));
//    }

    for (UIView *view in outputOrder) {

        [UIView animateWithDuration:kTrackLayoutAnimationDuration
                              delay:kTrackLayoutAnimationDelay
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{

                             view.frame = [[destinationFrames objectAtIndex:[outputOrder indexOfObject:view]] CGRectValue];
                         }
                         completion:nil
        ];

    }

}

- (BOOL)trackOrderUnchangedWithOutputOrder:(NSArray *)outputOrder inputOrder:(NSArray *)inputOrder {

    for (TrackView *track in outputOrder) {

        if ([outputOrder indexOfObject:track] != [inputOrder indexOfObject:track]) {
            return NO;
        }
    }

    ALog(@"track order unchanged");
    return YES;
}

- (void)echoTrackLocations {

    NSEnumerator *reversTraversal = [self.subviews reverseObjectEnumerator];
    TrackView *track;
    while (nil != (track = [reversTraversal nextObject])) {
//        ALog(@"%d. %@. %@. min | max %.0f | %.0f.", [self.subviews indexOfObject:track], [track class], CGRectGetMinY(track.frame), CGRectGetMaxY(track.frame));
    }

}

#pragma mark - Misc. Methods

- (NSString *)description {

    return [NSString stringWithFormat:@"%@. subviews %@.", [self class], (0 == [self.subviews count] ? @"empty" : self.subviews)];
}

@end
