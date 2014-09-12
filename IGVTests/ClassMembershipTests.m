//
// Created by turner on 5/13/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "BAMReader.h"
#import "BEDCodec.h"

@interface ClassMembershipTests : SenTestCase
@end

@implementation ClassMembershipTests

- (void)testIsMemberOfClass {

    Codec *codec = [[[Codec alloc] init] autorelease];
    STAssertNotNil(codec, nil);

    STAssertTrue([codec isMemberOfClass:[Codec class]], nil);
    STAssertTrue([codec isKindOfClass:[Codec class]], nil);

    STAssertTrue([codec class] == [Codec class], nil);

    BEDCodec *bedCodec = [[[BEDCodec alloc] init] autorelease];
    STAssertNotNil(bedCodec, nil);

//    STAssertTrue([bedCodec isMemberOfClass:[Codec class]], nil);
    STAssertTrue([bedCodec isKindOfClass:[Codec class]], nil);
//
//    STAssertTrue([bedCodec class] == [Codec class], nil);



//    NSArray *directSubclasses = [[codec class] subClasses];
//
//    STAssertNotNil(directSubclasses, nil);
//    for (Class directSubclass in directSubclasses) {
//
//        ALog(@"Direct subclasses %@", directSubclass);
//    }

}

@end