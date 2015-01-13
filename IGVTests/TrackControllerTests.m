//
// Created by turner on 1/3/13.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TrackController.h"
#import "LMResource.h"
#import "Logging.h"

@interface TrackControllerTests : SenTestCase
@end

@implementation TrackControllerTests

- (void)testTrackControllerCreation {

    LMResource *lmResource = [LMResource resourceWithName:nil filePath:@"https://dm.genomespace.org/datamanager/file/Home/igvtest/ipad/hg18_refseq_genes.bed" indexPath:nil];
    STAssertNotNil(lmResource, nil);
    ALog(@"%@", lmResource);

//    UINavigationController *rootContainerController = (UINavigationController *) [[[UIApplication sharedApplication] delegate] window].rootViewController;
//    STAssertNotNil(rootContainerController, nil);
//
//    RootContentController *rootContentController = (RootContentController *) rootContainerController.topViewController;
//    STAssertNotNil(rootContentController, nil);

    TrackController *trackController = [[[TrackController alloc] initWithResource:lmResource ] autorelease];
    STAssertNotNil(trackController, nil);

}

@end