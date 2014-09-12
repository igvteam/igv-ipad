//
//  Created by turner on 3/6/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "NSObject+ClassHierarchyTraversal.h"
#import "Codec.h"
#import "Logging.h"

@interface ClassHierarchyTraversalTests : SenTestCase
@end

@implementation ClassHierarchyTraversalTests

- (void)testNSObjectClassHierarchyTraversal {

    ALog(@"Base class: %@", [Codec class]);

    NSArray *allSubClasses = [Codec subClasses];

    STAssertNotNil(allSubClasses, nil);
    for (Class c in allSubClasses) {

        ALog(@"Direct subclasses %@", c);
    }

}

@end

