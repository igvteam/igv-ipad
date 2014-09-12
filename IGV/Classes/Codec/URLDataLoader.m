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
//  URLDataLoader.m
//
// This class wraps a NSURLRequest and responds to NSURLRequestDelegate methods.  It is designed to handle a single
// request and should not be reused.
//

#import "AsciiFeatureSource.h"
#import "RootContentController.h"
#import "Logging.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "FileRange.h"
#import "IGVHelpful.h"
#import "UIApplication+IGVApplication.h"

@interface URLDataLoader ()

@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) HTTPRequestCompletion completionHandler;
@property(nonatomic, copy) NSString *pass;
@property(nonatomic, copy) NSString *user;
@property(nonatomic, retain) HttpResponse *httpResponse;
@property(nonatomic, retain) NSMutableURLRequest *urlRequest;

- (id)initWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion;
- (id)initWithPath:(NSString *)path;
- (void)setRangeStart:(long long int)position size:(long long int)nbytes;
- (HttpResponse *)httpResponseFromLoadHeaderSynchronous;
- (void)loadDataSynchronousWithCompletion:(HTTPRequestCompletion)completion;
- (HttpResponse *)loadDataSynchronous;
- (void)performURLConnectionSynchronousWithMethod:(NSString *)method headers:(NSDictionary *)headers;
- (void)performURLConnectionWithMethod:(NSString *)method headers:(NSDictionary *)headers;
@end

@implementation URLDataLoader

@synthesize path = _path;
@synthesize urlRequest = _urlRequest;
@synthesize httpResponse = _httpResponse;
@synthesize completionHandler = _completionHandler;
@synthesize user = _user;
@synthesize pass = _pass;

- (void)dealloc {

    self.path = nil;
    self.urlRequest = nil;
    self.httpResponse = nil;
    self.completionHandler = nil;
    self.user = nil;
    self.pass = nil;

    [super dealloc];
}

- (id)initWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion {

    self = [self initWithPath:path];

    if (nil != self) {
        self.completionHandler = completion;
    }

    return self;

}

- (id)initWithPath:(NSString *)path {

    self = [super init];

    if (nil != self) {

        self.httpResponse = [[[HttpResponse alloc] init] autorelease];
        self.path = path;
        self.urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.path]
                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                              timeoutInterval:120.0];
    }

    return self;
}

- (void)performURLConnectionSynchronousWithMethod:(NSString *)method headers:(NSDictionary *)headers {

    [self.urlRequest setHTTPMethod:method];
    [self.urlRequest setValue:@"IGV Ipad/1.0" forHTTPHeaderField:@"User-Agent"];
    if (nil != headers) {
        for (NSString *key in headers.allKeys) {
            [self.urlRequest setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }

    NSURLResponse *urlResponse = nil;

    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:self.urlRequest returningResponse:&urlResponse error:&error];

    if (nil != error) {
        ALog(@"%@ ERROR: %@", [self class], [error localizedDescription]);
    }

    self.httpResponse.error = error;
    if (nil == data) {
        return;
    }

    self.httpResponse.receivedData = [[[NSMutableData alloc] initWithData:data] autorelease];
    self.httpResponse.nsURLResponse = urlResponse;
}

- (void)performURLConnectionWithMethod:(NSString *)method headers:(NSDictionary *)headers {

    [self.urlRequest setHTTPMethod:method];
    [self.urlRequest setValue:@"IGV Ipad/1.0" forHTTPHeaderField:@"User-Agent"];
    if (nil != headers) {
        for (NSString *key in headers.allKeys) {
            [self.urlRequest setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }

    [[[NSURLConnection alloc] initWithRequest:self.urlRequest delegate:self] autorelease];

}

- (HttpResponse *)httpResponseFromLoadHeaderSynchronous {

    [self performURLConnectionSynchronousWithMethod:@"HEAD" headers:nil];
    return self.httpResponse;

}

- (void)loadDataSynchronousWithCompletion:(HTTPRequestCompletion)completion {

    [self performURLConnectionSynchronousWithMethod:@"GET" headers:nil];

    completion(self.httpResponse);
}

- (HttpResponse *)loadDataSynchronous {

    [self performURLConnectionSynchronousWithMethod:@"GET" headers:nil];

    return self.httpResponse;
}

- (void)setRangeStart:(long long int)position size:(long long int)nbytes {

//    NSString *byteRange = [NSString stringWithFormat:@"bytes=%lld-%lld", position, position + nbytes];
    NSString *byteRange = [NSString stringWithFormat:@"bytes=%lld-%lld", position, position + nbytes - 1];

    [self.urlRequest setValue:byteRange forHTTPHeaderField:@"Range"];
}

+ (void)loadDataWithPath:(NSString *)path forRange:(FileRange *)fileRange completion:(HTTPRequestCompletion)completion {

    URLDataLoader *loader = [[[URLDataLoader alloc] initWithPath:path completion:completion] autorelease];
    [loader setRangeStart:fileRange.position size:fileRange.byteCount];
    [loader performURLConnectionWithMethod:@"GET" headers:nil];
}

+ (void)loadDataWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion {

    URLDataLoader *loader = [[[URLDataLoader alloc] initWithPath:path completion:completion] autorelease];
    [loader performURLConnectionWithMethod:@"GET" headers:nil];
}

+ (void)loadHeaderWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion {

    URLDataLoader *loader = [[[URLDataLoader alloc] initWithPath:path completion:completion] autorelease];
    [loader performURLConnectionWithMethod:@"HEAD" headers:nil];
}

+ (void)loadDataSynchronousWithPath:(NSString *)path forRange:(FileRange *)range completion:(HTTPRequestCompletion)completion {

    URLDataLoader *loader = [[[URLDataLoader alloc] initWithPath:path] autorelease];
    [loader setRangeStart:range.position size:range.byteCount];

    [loader loadDataSynchronousWithCompletion:completion];
}

+ (HttpResponse *)loadDataSynchronousWithPath:(NSString *)path forRange:(FileRange *)range {

    URLDataLoader *loader = [[[URLDataLoader alloc] initWithPath:path] autorelease];
    [loader setRangeStart:range.position size:range.byteCount];

    return [loader loadDataSynchronous];
}

+ (HttpResponse *)loadDataSynchronousWithPath:(NSString *)path {

    URLDataLoader *loader = [[[URLDataLoader alloc] initWithPath:path] autorelease];

    return [loader loadDataSynchronous];
}

+ (HttpResponse *)loadHeaderSynchronousWithPath:(NSString *)path {

    URLDataLoader *loader = [[[URLDataLoader alloc] initWithPath:path] autorelease];

    return [loader httpResponseFromLoadHeaderSynchronous];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse {

    self.httpResponse.nsURLResponse = aResponse;
    [self.httpResponse.receivedData setLength:0];

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

    [self.httpResponse.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    self.completionHandler(self.httpResponse);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)aError {

    self.httpResponse.error = aError;
    self.completionHandler(self.httpResponse);

}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

    ALog(@"Authentication attempt %d.", [challenge previousFailureCount]);

    if ([challenge previousFailureCount] > 3) {

        ALog(@"Authentication Error. Too many %d unsuccessul login attempts.", [challenge previousFailureCount]);

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                        message:@"Too many unsuccessul login attempts."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];

        [alert show];
        [alert release];

    } else {
        AuthenticationController *authenticationController = [[[AuthenticationController alloc] initWithNibName:nil bundle:nil] autorelease];
        authenticationController.modalPresentationStyle = UIModalPresentationFormSheet;
        authenticationController.delegate = self;
        authenticationController.challenge = challenge;

        UINavigationController *rootContainerController = (UINavigationController *) [[[UIApplication sharedApplication] delegate] window].rootViewController;
        RootContentController *rootContentController = (RootContentController *) rootContainerController.topViewController;

        [rootContentController presentViewController:authenticationController animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark AuthenticationDelegate Methods

- (void)authenticationController:(AuthenticationController *)authenticationController username:(NSString *)username password:(NSString *)password {

    UINavigationController *rootContainerController = (UINavigationController *) [[[UIApplication sharedApplication] delegate] window].rootViewController;
    RootContentController *rootContentController = (RootContentController *) rootContainerController.topViewController;

    if (nil == username || nil == password) {

        [[authenticationController.challenge sender] cancelAuthenticationChallenge:authenticationController.challenge];

        // TODO - dat - Is this the best way to handle this?
        self.completionHandler(nil);

    } else {

        //   self.user = username;
        //   self.pass = password;

        NSURLCredential *credential = [[[NSURLCredential alloc] initWithUser:username password:password persistence:NSURLCredentialPersistenceForSession] autorelease];
        [[authenticationController.challenge sender] useCredential:credential forAuthenticationChallenge:authenticationController.challenge];
    }

    [rootContentController dismissViewControllerAnimated:YES completion:nil];

}

@end
