//
//  NSDataGzipTests.m
//  IGV
//
//  Created by turner on 7/10/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "NSData+GZIP.h"

@interface NSDataGzipTests : SenTestCase
@end

@implementation NSDataGzipTests


- (void)testOutputEqualsInput {

    //set up data
    NSString *inputString = @"Hello World!";
    NSData *inputData = [inputString dataUsingEncoding:NSUTF8StringEncoding];

    //compress
    NSData *compressedData = [inputData gzippedData];

    //decode
    NSData *outputData = [compressedData gunzippedData];
    NSString *outputString = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
    STAssertEqualObjects(outputString, inputString, @"OutputEqualsInput test failed");
}

- (void)testZeroLengthInput {
    NSData *data = [[NSData data] gzippedData];

    STAssertNil(data, @"ZeroLengthInput test failed");

    data = [[NSData data] gunzippedData];
    STAssertNil(data, @"ZeroLengthInput test failed");
}

@end
