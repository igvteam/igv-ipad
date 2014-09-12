//
//  TrackDelegateTests.m
//  IGV
//
//  Created by turner on 12/17/13.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "ITrackDelegateProtocol.h"
#import "TrackDelegate.h"
#import "TrackView.h"
#import "Logging.h"

@interface TrackDelegateTests : SenTestCase
@end

@implementation TrackDelegateTests

- (void)testCreateTrackSquasherExpander {

    id <ITrackDelegateProtocol> trackDelegate = [[[TrackDelegate alloc] init] autorelease];
    STAssertNotNil(trackDelegate, nil);

    TrackView *track = [[[TrackView alloc] initWithFrame:CGRectMake(0, 0, 1024, 512)] autorelease];
    [trackDelegate animateTrack:track toTargetHeight:1024];
}

- (void)testExample {
    STAssertTrue(YES, nil);
}

@end
