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

#import <Foundation/Foundation.h>
#import "AuthenticationController.h"
#import "FeatureSource.h"


typedef void (^HTTPRequestCompletion)(HttpResponse* response);

@class FileRange;

@interface URLDataLoader : NSObject <AuthenticationDelegate>

// Asynchronous methods
+ (void)loadDataWithPath:(NSString *)path forRange:(FileRange *)fileRange completion:(HTTPRequestCompletion)completion;
+ (void)loadDataWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion;
+ (void)loadHeaderWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion;

// Synchronous methods
+ (void)loadDataSynchronousWithPath:(NSString *)path forRange:(FileRange *)range  completion:(HTTPRequestCompletion)completion;
+ (HttpResponse *)loadDataSynchronousWithPath:(NSString *)path forRange:(FileRange *)range;
+ (HttpResponse *)loadDataSynchronousWithPath:(NSString *)path;
+ (HttpResponse *)loadHeaderSynchronousWithPath:(NSString *)path;

@end



