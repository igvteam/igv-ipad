//
//  FileRangeTests.m
//  IGV
//
//  Created by turner on 1/29/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "FileRange.h"
#import "Logging.h"

@interface FileRangeTests : SenTestCase
@end

@implementation FileRangeTests

- (void)testFileRangeCreation {

    FileRange *fileRange = [[[FileRange alloc] initWithPosition:0 byteCount:24] autorelease];
    STAssertNotNil(fileRange, nil);

    ALog(@"%@", fileRange);
}

- (void)testExample {
    STAssertTrue(YES, nil);
}

@end
