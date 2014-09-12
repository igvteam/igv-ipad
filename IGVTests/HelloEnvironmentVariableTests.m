//
//  HelloEnvironmentVariableTests.m
//  IGV
//
//  Created by turner on 1/8/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "Logging.h"

@interface HelloEnvironmentVariableTests : SenTestCase
@end

@implementation HelloEnvironmentVariableTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testEnvironmentVariable
{
    ALog(@"%@", [[[NSProcessInfo processInfo] environment] objectForKey:@"RUN_UNIT_TEST_ONLY"]);
    NSString *runUnitTestOnly = [[[NSProcessInfo processInfo] environment] objectForKey:@"RUN_UNIT_TEST_ONLY"];

    STAssertTrue(1 == [runUnitTestOnly intValue], nil);
}

@end
