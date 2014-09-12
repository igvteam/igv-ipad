//
//  PListPersistenceTests.m
//  IGV
//
//  Created by turner on 4/3/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "Logging.h"
#import "PListPersistence.h"

@interface PListPersistenceTests : SenTestCase
@end

@implementation PListPersistenceTests

- (void)testReadPersistencePlistWithPropertyListPListPersistence {

    PListPersistence *pListPersistence = [[[PListPersistence alloc] init] autorelease];
    STAssertNotNil(pListPersistence, nil);

    NSError *error = nil;
    BOOL success = NO;
    success = [pListPersistence usePListPrefix:@"defaultSession"];
    STAssertTrue(success, nil);
    STAssertNil(error, nil);


    NSMutableDictionary *dictionary = [pListPersistence plistDictionary];
    STAssertNotNil(dictionary, nil);
    ALog(@"%@", dictionary)

}

- (void)testWritePropertyListAndPersistWithPListPersistence {

    PListPersistence *pListPersistence = [[[PListPersistence alloc] init] autorelease];
    STAssertNotNil(pListPersistence, nil);

    BOOL success = NO;
    NSError *error = nil;
    success = [pListPersistence usePListPrefix:@"defaultSession"];
    STAssertTrue(success, nil);
    STAssertNil(error, nil);

    NSMutableDictionary *dictionary = [pListPersistence plistDictionary];
    STAssertNotNil(dictionary, nil);
    ALog(@"BEFORE %@", dictionary)

    NSMutableDictionary *session = [NSMutableDictionary dictionary];
    [session setObject:@"hg19" forKey:@"genome"];
    [session setObject:@"chr13:1234-5678" forKey:@"locus"];

    NSMutableArray *tracks = [NSMutableArray array];
    NSArray *keys = [NSArray arrayWithObjects:@"name", @"path", @"squish", nil];
    NSDictionary *track;
    NSArray *objs;

    objs = [NSArray arrayWithObjects:@"jim track", @"http://www.jim.com/track", [NSNumber numberWithBool:NO], nil];
    track = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
    [tracks addObject:track];

    objs = [NSArray arrayWithObjects:@"helga track", @"http://www.helga.is/track", [NSNumber numberWithBool:YES], nil];
    track = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
    [tracks addObject:track];

    objs = [NSArray arrayWithObjects:@"dugla track", @"http://www.dugla.com/track", [NSNumber numberWithBool:NO], nil];
    track = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
    [tracks addObject:track];

    [session setObject:tracks forKey:@"tracks"];

    [dictionary setObject:session forKey:@"duglaSession"];
    [pListPersistence writePListDictionary:dictionary];
    STAssertTrue(success, nil);
    STAssertNil(error, nil);

    NSMutableDictionary *echo = [pListPersistence plistDictionary];
    STAssertNotNil(echo, nil);
    ALog(@" AFTER %@", echo)

};

- (void)testInitializeUserDefinedGenomePersistence {

    PListPersistence *pListPersistence = [[[PListPersistence alloc] init] autorelease];
    STAssertNotNil(pListPersistence, nil);

    BOOL success = NO;
    NSError *error = nil;

    success = [pListPersistence initializePersistenceWithPlistInBundlePrefix:@"defaultUserDefinedGenome" error:&error];
    STAssertTrue(success, nil);
    STAssertNil(error, nil);

    NSMutableDictionary *dictionary = [pListPersistence plistDictionary];
    STAssertNotNil(dictionary, nil);
    ALog(@"%@", dictionary);
};

- (void)testInitializeSessionPersistence {

    PListPersistence *pListPersistence = [[[PListPersistence alloc] init] autorelease];
    STAssertNotNil(pListPersistence, nil);

    BOOL success = NO;
    NSError *error = nil;

    success = [pListPersistence initializePersistenceWithPlistInBundlePrefix:@"defaultSession" error:&error];
    STAssertTrue(success, nil);
    STAssertNil(error, nil);

    NSMutableDictionary *dictionary = [pListPersistence plistDictionary];
    STAssertNotNil(dictionary, nil);
    ALog(@"%@", dictionary);
};

- (void)testCreatePropertyListPListPersistence {

    PListPersistence *persistenceController = [[[PListPersistence alloc] init] autorelease];
    STAssertNotNil(persistenceController, nil);

}

@end
