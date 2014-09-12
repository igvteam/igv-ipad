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
// Created by turner on 2/25/13.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "NSMutableDictionary+TrackController.h"
#import "TrackController.h"
#import "RefSeqTrackController.h"
#import "TrackContainerScrollView.h"
#import "UIApplication+IGVApplication.h"
#import "LMResource.h"
#import "CytobandTrackView.h"
#import "RulerView.h"

@implementation NSMutableDictionary (TrackController)

- (void)renderTrack:(TrackView *)track {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    rootContentController.remainingTrackRenderings = 1;
    [track setNeedsDisplay];
}

- (void)renderAllTracks {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    [rootContentController.cytobandTrack setNeedsDisplay];
    [rootContentController.rulerView setNeedsDisplay];

    rootContentController.remainingTrackRenderings = [self count];

    id refSeqKey = NSStringFromClass([RefSeqTrackController class]);
    TrackController *refSeqTrackController = [self objectForKey:refSeqKey];
    [refSeqTrackController.track setNeedsDisplay];

    NSArray *keys = [self allNonRefSeqKeys];
    for (NSString *key in keys) {

        TrackController *trackController = [self objectForKey:key];
        [trackController.track setNeedsDisplay];
    }
}

- (NSArray *)allNonRefSeqKeys {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    rootContentController.trackContainerScrollView.geneTrack = nil;

    NSMutableSet *keys = [NSMutableSet setWithArray:[self allKeys]];
    [keys minusSet:[NSSet setWithObject:NSStringFromClass([RefSeqTrackController class])]];

    return [NSArray arrayWithArray:[keys allObjects]];
}

- (void)removeAllTracks {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    rootContentController.trackContainerScrollView.geneTrack = nil;

    NSMutableSet *keys = [NSMutableSet setWithArray:[self allKeys]];
    [keys minusSet:[NSSet setWithObject:NSStringFromClass([RefSeqTrackController class])]];
    for (NSString *key in keys) {

        TrackController *trackController = [self objectForKey:key];
        trackController.track.resource.enabled = NO;
        [rootContentController.trackContainerScrollView discardTrack:trackController.track];
        [self removeObjectForKey:key];
    }
}

@end