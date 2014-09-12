//
// Created by turner on 12/13/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "LMTree.h"
#import "Logging.h"
#import "LMCategory.h"

@interface LMCategoryTests : SenTestCase
@end

@implementation LMCategoryTests

- (void)testDetectEmptyLeaves {

    NSString *urlString = @"http://www.broadinstitute.org/igvdata/annotations/hg18/hg18_annotations.xml";
//    NSString *path = @"http://gdac.broadinstitute.org/tap/igv/load/tcga_hg19.xml";

    LMTree *tree = [LMTree treeWithPath:urlString error:NULL];
    STAssertNotNil(tree, nil);

    [tree.rootCategory cullAssessment];
    ALog(@"\nBEFORE %@", tree.rootCategory);

    [tree.rootCategory cullChildCategories];
    ALog(@"\nAFTER %@", tree.rootCategory);
}

@end