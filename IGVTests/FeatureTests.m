//
//  Created by turner on 3/23/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Feature.h"
#import "Logging.h"
#import "LabeledFeature.h"

@interface FeatureTests : SenTestCase
@end

@implementation FeatureTests

- (void)testFeatureCreation {

    Feature *feature = [[[Feature alloc] initWithStart:123456789 end:234567890] autorelease];
    ALog(@"%@", feature);

    STAssertNotNil(feature, nil);

}

- (void)testLabeledFeatureCreation {

    LabeledFeature *feature = [[[LabeledFeature alloc] initWithStart:1234 end:4321 label:@"1234-4321"] autorelease];
    ALog(@"%@", feature);

    STAssertNotNil(feature, nil);

}

@end