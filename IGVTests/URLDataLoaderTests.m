//
// Created by jrobinso on 7/7/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <SenTestingKit/SenTestingKit.h>
#import "URLDataLoader.h"
#import "Logging.h"
#import "LittleEndianByteBuffer.h"
#import "HttpResponse.h"
#import "FileRange.h"


@interface URLDataLoaderTests : SenTestCase
@property(nonatomic, retain) HttpResponse *httpResponse;
@end

@implementation URLDataLoaderTests

@synthesize httpResponse = _httpResponse;

- (void)dealloc {

    self.httpResponse = nil;
    [super dealloc];
}

- (void)waitTillDone {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:1];
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if ([timeoutDate timeIntervalSinceNow] < 0.0) {
            break;
        }
    }
    while (nil == self.httpResponse);

}

- (void)testLoadDataSynchronous {

    NSString *urlString = @"http://www.broadinstitute.org/igvdata/ipad/byteRangeTest.txt";

    self.httpResponse = nil;
    self.httpResponse = [URLDataLoader loadDataSynchronousWithPath:urlString];

    STAssertNil(self.httpResponse.error, nil);

    NSInteger statusCode = self.httpResponse.statusCode;
    STAssertEquals(200, statusCode, @"Status code");

    long long contentLength = self.httpResponse.contentLength;
    STAssertEquals(26ll, contentLength, nil);

}

- (void)testLoadHeaderSynchronous {

    NSString *urlString = @"http://www.broadinstitute.org/igvdata/ipad/byteRangeTest.txt";

    self.httpResponse = nil;
    self.httpResponse = [URLDataLoader loadHeaderSynchronousWithPath:urlString];

    STAssertNil(self.httpResponse.error, nil);

    NSInteger statusCode = self.httpResponse.statusCode;
    STAssertEquals(200, statusCode, @"Status code");

    long long contentLength = self.httpResponse.contentLength;
    STAssertEquals(26ll, contentLength, @"Content Length");

}

- (void)testLoadByteRangeSynchronous {

    self.httpResponse = nil;

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/byteRangeTest.txt";

    FileRange *range = [FileRange rangeWithPosition:10 byteCount:10];
    self.httpResponse = [URLDataLoader loadDataSynchronousWithPath:path forRange:range];

    STAssertNil(self.httpResponse.error, nil);

    NSInteger statusCode = self.httpResponse.statusCode;
    STAssertTrue(statusCode == 206, nil);

    NSString *contents = self.httpResponse.receivedString;
    ALog(@"%@", contents);

    STAssertTrue([self.httpResponse.receivedString isEqualToString:@"klmnopqrst"], nil);

}

- (void)testLoadByteRangeSynchronous2 {

    self.httpResponse = nil;

    NSString *path = @"http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalK562H3k4me3.tdf";

    FileRange *range = [FileRange rangeWithPosition:24 byteCount:1077];
    self.httpResponse = [URLDataLoader loadDataSynchronousWithPath:path forRange:range];

    STAssertNil(self.httpResponse.error, nil);

    NSInteger statusCode = self.httpResponse.statusCode;
    STAssertTrue(statusCode == 206, nil);

    LittleEndianByteBuffer *littleEndianByteBuffer = [[[LittleEndianByteBuffer alloc] initWithData:self.httpResponse.receivedData] autorelease];
    STAssertNotNil(littleEndianByteBuffer, nil);

    int nWFs = [littleEndianByteBuffer nextInt];
    for (int i = 0; i < nWFs; i++) {
        NSString *wf = [littleEndianByteBuffer nextString];
        ALog(@"%@", wf);
    }
}

- (void)testBogusResource {

    self.httpResponse = nil;

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/nothingToSeeHere";

    self.httpResponse = [URLDataLoader loadHeaderSynchronousWithPath:path];
    ALog(@"data %d error %@", [self.httpResponse.receivedData length], self.httpResponse.error == nil ? @"nil" : @"not-nil");

    STAssertNotNil(self.httpResponse.error, @"error NOT raised");

    NSInteger statusCode = self.httpResponse.statusCode;
    STAssertEquals(404, statusCode, @"Status code");

}

- (void)testBogusHost {

    self.httpResponse = nil;

    NSString *path = @"http://www.nosuchserver.org/nothingToSeeHere";

    self.httpResponse = [URLDataLoader loadHeaderSynchronousWithPath:path];

    STAssertNotNil(self.httpResponse.error, nil);

    NSInteger statusCode = self.httpResponse.statusCode;
    STAssertEquals(-1, statusCode, @"Status code");

}

@end