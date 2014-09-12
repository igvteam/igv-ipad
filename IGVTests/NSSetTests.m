//
//  NSSetTests.m
//  IGV
//
//  Created by turner on 10/31/13.
//
//

#import <SenTestingKit/SenTestingKit.h>

@interface NSSetTests : SenTestCase
@end

@implementation NSSetTests

- (void)testSetSubset {

    NSSet *commands = [NSSet setWithObjects:@"alfa", @"bravo", @"charlie", @"delta", @"echo", nil];
    NSSet *these = [NSSet setWithObjects:@"bravo", @"delta", nil];

    STAssertTrue([these isSubsetOfSet:commands], nil);
}

@end
