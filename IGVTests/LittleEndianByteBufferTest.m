//
// Created by jrobinso on 7/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Logging.h"
#import "LittleEndianByteBuffer.h"

@interface LittleEndianByteBufferTest : SenTestCase
@end


//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"tracklines_test" ofType:@"wig"];
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"wiggleFixedStepExample" ofType:@"wig"];
//STAssertNotNil(filePath, nil);

//NSData *data = [NSData dataWithContentsOfFile:filePath];


@implementation LittleEndianByteBufferTest

- (void)testRead {

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"les_test" ofType:@"bin"];
    STAssertNotNil(filePath, nil);
    NSData *data = [NSData dataWithContentsOfFile:filePath];

    LittleEndianByteBuffer *les = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    NSString *testString = @"Binary test file";
    NSString *str = [les nextString];
    STAssertEqualObjects(testString, str, @"String");


    float MAX_FLOAT =  3.4028235E38;
    float f = [les nextFloat];
    STAssertEquals(f, MAX_FLOAT, @"float");

    ALog(@"%f", f);

}

@end