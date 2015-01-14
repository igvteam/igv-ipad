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
//  Created by turner on 3/3/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "RootScrollView.h"
#import "NSString+FileURLAndLocusParsing.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
/*
 if (SYSTEM_VERSION_LESS_THAN(@"5.0")) {
 // code here
 }
 
 if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
 // code here
 }
*/

@interface NSMutableArray (Reverse)
- (void)reverse;
@end

@interface NSString (IGVStringWithUnichar)
+ (NSString *) stringWithUnichar: (unichar) value;
@end

typedef void (^IGVVoidBlockType)();

@interface IGVHelpful : NSObject <UIAlertViewDelegate>

@property(nonatomic, retain) NSNumberFormatter *basesNumberFormatter;

- (void)executeOnMainThread:(IGVVoidBlockType)block;

+ (BOOL)isReachablePath:(NSString *)path;

+ (NSString *)prettyPrintLongLongInt:(long long int)longLongInteger;

+ (bool)networkStatus;

- (void)presentError:(NSError *)error;

+ (BOOL)errorDetected:(NSError *)error;

- (void)presentErrorMessage:(NSString *)errorMessage;

+ (NSError *)errorWithDetailString:(NSString *)detailString;

+ (NSString *)rootScrollViewScrollThresholdName:(RSVScrollThreshold)scrollThreshold;

+ (NSString *)gestureRecognizerStateName:(UIGestureRecognizerState)gestureState;

+ (NSString *)locusListItemFormatName:(LocusListFormat)locusListFormat;

+ (UIImage *)imageScreenShotWithView:(UIView *)aView;

+ (IGVHelpful *)sharedIGVHelpful;

+ (BOOL)isSupportedPath:(NSString *)path blurb:(NSString **)blurb;

+ (void)prettyPrintLine:(CGRect)rect blurb:(NSString *)blurb;

+ (void)prettyPrintRect:(CGRect)rect blurb:(NSString *)blurb;

+ (void)prettyPrintSize:(CGSize)size blurb:(NSString *)blurb;

+ (void)prettyPrintCGAffineTransform:(CGAffineTransform)transform blurb:(NSString *)blurb;

+ (UIColor *)colorWithCommaSeparateRGBString:(NSString *)rgbString;

+ (BOOL)isValidStatusCode:(NSInteger)statusCode;

+ (BOOL)isUsablePath:(NSString *)path blurb:(NSString **)blurb;

+ (BOOL)isUsableIndexPath:(NSString *)indexPath blurb:(NSString **)blurb;
@end
