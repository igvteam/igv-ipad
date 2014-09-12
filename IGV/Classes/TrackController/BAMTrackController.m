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
//  Created by turner on 3/10/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "BAMTrackController.h"
#import "IGVContext.h"
#import "AlignmentTrackView.h"
#import "CoverageTrackView.h"
#import "BAMReader.h"
#import "BAMReader.h"
#import "Logging.h"
#import "LMResource.h"
#import "LMResource.h"
#import "FeatureList.h"
#import "AlignmentResults.h"
#import "RefSeqTrackView.h"
#import "IGVAppDelegate.h"
#import "UIApplication+IGVApplication.h"
#import "FeatureInterval.h"
#import "NSString+FileURLAndLocusParsing.h"
#import "RefSeqFeatureList.h"
#import "LocusListItem.h"
#import "TrackDelegate.h"
#import "AlignmentRow.h"

@interface BAMTrackController ()
@end

@implementation BAMTrackController

@synthesize bamReader;

- (void)dealloc {

    self.bamReader = nil;

    [super dealloc];
}

- (id)initWithResource:(LMResource *)resource {

    self = [super init];

    if (nil != self) {

        self.bamReader = [[[BAMReader alloc] initWithPath:resource.path] autorelease];

        AlignmentTrackView *alignmentTrack = [[[AlignmentTrackView alloc] initWithFrame:[AlignmentTrackView trackFrame]
                                                                               resource:resource
                                                                          trackDelegate:[[[TrackDelegate alloc] init] autorelease]
                                                                        trackController:self] autorelease];

        self.track = alignmentTrack;
    }

    return self;
}

@end