//
//  Created by turner on 2/13/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "FileListItem.h"
#import "Logging.h"

@interface FileListItemTests : SenTestCase
@end

@implementation FileListItemTests

- (void)testFileListItemCreationWithNilLabel {

    FileListItem *fileListItem = [[[FileListItem alloc] initWithFilePath:@"http://www.broadinstitute.org/igvdata/1KG/pilot2Bams/NA12878.SLX.bam" label:nil genome:nil] autorelease];
    STAssertNotNil(fileListItem, nil);

    ALog(@"%@", fileListItem);

    fileListItem.enabled = YES;
    STAssertTrue(YES == fileListItem.enabled, nil);

}

@end