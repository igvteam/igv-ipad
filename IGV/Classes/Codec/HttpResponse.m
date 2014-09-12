// 
// The MIT License (MIT)
// 
// 
// Copyright (c) 2014 Broad Institute
// 
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


//
// Created by jrobinso on 7/22/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "HttpResponse.h"
#import "FeatureInterval.h"
#import "TrackView.h"
#import "FeatureList.h"

@interface HttpResponse ()
- (BOOL)nsURLResponseIsValid;
@end

@implementation HttpResponse

@synthesize receivedData=_receivedData;
@synthesize error=_error;
@synthesize nsURLResponse=_nsURLResponse;

- (void)dealloc {

    self.receivedData = nil;
    self.error = nil;
    self.nsURLResponse = nil;

    [super dealloc];
}

- (NSMutableData *)receivedData {

    if (nil == _receivedData) {
        self.receivedData = [NSMutableData data];
    }

    return _receivedData;
}

- (NSDictionary *)responseHeaderFields {

    if (![self nsURLResponseIsValid]) return nil;

    return ((NSHTTPURLResponse *) self.nsURLResponse).allHeaderFields;
}

- (NSInteger)statusCode {

    if (![self nsURLResponseIsValid]) return -1;

    return ((NSHTTPURLResponse *) self.nsURLResponse).statusCode;
 }

- (long long)contentLength {

    if (![self nsURLResponseIsValid]) return -1;

    return ((NSHTTPURLResponse *) self.nsURLResponse).expectedContentLength;
}

- (BOOL)nsURLResponseIsValid {
    return self.nsURLResponse != nil && [self.nsURLResponse isMemberOfClass:[NSHTTPURLResponse class]];
}

// Return the data as a string, using the encoding specfied in the response.
- (NSString *)receivedString {

    NSStringEncoding enc = NSASCIIStringEncoding; // Default fallback

    NSString *textEncodingName = self.nsURLResponse.textEncodingName;

    if (textEncodingName) {

        CFStringEncoding cfEnc = CFStringConvertIANACharSetNameToEncoding((CFStringRef) textEncodingName);
        enc = CFStringConvertEncodingToNSStringEncoding(cfEnc);
    }

    return [[[NSString alloc] initWithData:self.receivedData encoding:enc] autorelease];
}

-(NSString *)description {

    return [NSString stringWithFormat:@"%@ status %d data %d", [self class], self.statusCode, [self.receivedData length]];
}

- (BOOL)statusCodeIsSuccess {
    return (200 <= [self statusCode] && [self statusCode] < 300);
}
@end