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

#import "FileURLDialogController.h"
#import "BaseFeatureSource.h"
#import "RootContentController.h"
#import "Codec.h"
#import "IGVHelpful.h"
#import "Logging.h"
#import "Reachability.h"

@implementation NSMutableArray (Reverse)

- (void)reverse {

    if ([self count] == 0) return;

    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {

        [self exchangeObjectAtIndex:i withObjectAtIndex:j];
        i++;
        j--;
    }
}

@end

@implementation NSString (IGVStringWithUnichar)

+ (NSString *) stringWithUnichar:(unichar) value {
    NSString *str = [NSString stringWithFormat: @"%C", value];
    return str;
}

@end

@implementation IGVHelpful

@synthesize basesNumberFormatter;

- (void)dealloc {

    self.basesNumberFormatter = nil;

    [super dealloc];
}

-(void)executeOnMainThread:(IGVVoidBlockType) block {

    if ([NSThread isMainThread])  {

        block();

    } else {

        dispatch_async(dispatch_get_main_queue(), ^{

            block();
        });

    }
}

+ (BOOL)isReachablePath:(NSString *)path {

    // Request just the header
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    [request setHTTPMethod: @"HEAD"];

    NSHTTPURLResponse* response = nil;
    NSError* error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    NSInteger responseStatusCode = [response statusCode];
    NSUInteger dataLength = [data length];
    long long int expectedResponseContentLength = [response expectedContentLength];

    if (nil != error) {
        ALog(@"ERROR %@", [error localizedDescription]);
        return NO;
    }

    BOOL success = [self isValidStatusCode:responseStatusCode];

    return success;
}

+ (NSString *)prettyPrintLongLongInt:(long long int)longLongInteger {
    return [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:longLongInteger]];;
}

+ (bool)networkStatus {

    return ReachableViaWiFi == [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
}

- (void)presentError:(NSError *)error {

    if (nil == error) return;

    NSString *localizedDescription = [error localizedDescription];

    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:localizedDescription
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil] autorelease];

    [alertView show];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });

}

- (void)alertViewCancel:(UIAlertView *)alertView {
    ALog(@"%@.", [self class]);
}

- (NSNumberFormatter *)basesNumberFormatter {

    if (nil == basesNumberFormatter) {

        self.basesNumberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        [self.basesNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }

    return basesNumberFormatter;
}

+ (BOOL)errorDetected:(NSError *)error {
    return nil != error && nil != error;
}

- (void)presentErrorMessage:(NSString *)errorMessage {

    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:errorMessage
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil] autorelease];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });

}

- (NSString *)rangeStringWithRange:(NSUInteger)range {

    double digit;
    NSString *formatedNumber;
    if (range > 999999) {

        digit = range;
        digit /= 1e6;

        formatedNumber = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithDouble:digit]];
        return [NSString stringWithFormat:@"MB(%@)", formatedNumber];
    } else if (range > 999) {

        digit = range;
        digit /= 1e3;

        formatedNumber = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithDouble:digit]];
        return [NSString stringWithFormat:@"KB(%@)", formatedNumber];
    } else {

        formatedNumber = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithUnsignedInteger:(range)]];
        return [NSString stringWithFormat:@"B(%@)", formatedNumber];
    }

}

+ (NSError *)errorWithDetailString:(NSString *)detailString {

    if (nil != detailString) {

        return [NSError errorWithDomain:@"com.broadinstitute.igv.ErrorDomain"
                                   code:100
                               userInfo:[NSDictionary dictionaryWithObject:detailString forKey:NSLocalizedDescriptionKey]];
    }

    return nil;
}

+ (NSString *)rootScrollViewScrollThresholdName:(RSVScrollThreshold)scrollThreshold {

    NSString *result = nil;

    switch (scrollThreshold) {

        case RSVScrollThresholdUnevaluated:
            result = @"threshold unevaluated";
            break;

        case RSVScrollThresholdNone:
            result = @"threshold none";
            break;

        case RSVScrollThresholdLeft:
            result = @"threshold left";
            break;

        case RSVScrollThresholdRight:
            result = @"threshold right";
            break;

        case RSVScrollThresholdLeftAndRight:
            result = @"threshold left & right";
            break;

        default:
            result = @"threshold unknown";
    }

    return result;
}

+ (NSString *)gestureRecognizerStateName:(UIGestureRecognizerState)gestureState {

    NSString *result = nil;

    switch (gestureState) {

        case UIGestureRecognizerStatePossible:
            result = @"Gesture Recognizer State Possible";
            break;

        case UIGestureRecognizerStateBegan:
            result = @"Gesture Recognizer State Began";
            break;

        case UIGestureRecognizerStateChanged:
            result = @"Gesture Recognizer State Changed";
            break;

        case UIGestureRecognizerStateEnded:
            result = @"Gesture Recognizer State Ended";
            break;

        case UIGestureRecognizerStateCancelled:
            result = @"Gesture Recognizer State Cancelled";
            break;

        case UIGestureRecognizerStateFailed:
            result = @"Gesture Recognizer State Failed";
            break;

        default:
            result = @"Unrecognized Gesture State";
    }

    return result;
}

+ (NSString *)deviceOrientatioName:(UIDeviceOrientation)orientation {

    NSString *result = nil;

    switch (orientation) {

        case UIDeviceOrientationPortrait:
            result = @"Device Orientation Portrait";
            break;

        case UIDeviceOrientationPortraitUpsideDown:
            result = @"Device Orientation Portrait UpsideDown";
            break;

        case UIDeviceOrientationLandscapeLeft:
            result = @"Device Orientation LandscapeLeft";
            break;

        case UIDeviceOrientationLandscapeRight:
            result = @"Device Orientation LandscapeRight";
            break;

        case UIDeviceOrientationFaceUp:
            result = @"Device Orientation FaceUp";
            break;

        case UIDeviceOrientationFaceDown:
            result = @"Device Orientation FaceDown";
            break;

        case UIDeviceOrientationUnknown:
            result = @"Device Orientation Unknown";
            break;

        default:
            result = @"Device Orientation Unknown";
    }

    return result;
}

+ (NSString *)locusListItemFormatName:(LocusListFormat)locusListFormat {

    NSString *result = nil;

    switch (locusListFormat) {

        case LocusListFormatInvalid:
            result = @"LocusListFormatInvalid";
            break;

        case LocusListFormatChrLocusCentroid:
            result = @"LocusListFormatChrLocusCentroid";
            break;

        case LocusListFormatChrStartEnd:
            result = @"LocusListFormatChrStartEnd";
            break;

        case LocusListFormatChrFullExtent:
            result = @"LocusListFormatChrFullExtent";
            break;

        default:
            result = @"Unknown LocusListFormat";
    }

    return result;
}

+ (UIImage *)imageScreenShotWithView:(UIView *)aView {

    UIGraphicsBeginImageContextWithOptions(aView.bounds.size, NO, 0);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);

    [aView.layer renderInContext:context];

    CGContextRestoreGState(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

+(IGVHelpful *)sharedIGVHelpful {

    static dispatch_once_t pred;
    static IGVHelpful *shared = nil;

    dispatch_once(&pred, ^{

        shared = [[IGVHelpful alloc] init];
    });

    return shared;
}

+ (BOOL)isSupportedPath:(NSString *)path blurb:(NSString **)blurb {

    NSString *pathCooked = [[path lowercaseString] stringByReplacingOccurrencesOfString:@".gz" withString:@""];
    NSString *pathExtension = [pathCooked pathExtension];

    if ([pathExtension isEqualToString:@"txt"]) {

        return [self isSupportedPath:[path stringByReplacingOccurrencesOfString:@".txt" withString:@""] blurb:blurb];
    }

    BOOL success = NO;
    success |= [pathExtension isEqualToString:@"tdf"];

    success |= [pathExtension isEqualToString:@"bam"];

    success |= [pathExtension isEqualToString:@"bw"];
    success |= [pathExtension isEqualToString:@"bigwig"];

    // TODO - dat - testing
    success |= [pathExtension isEqualToString:@"bb"];
    success |= [pathExtension isEqualToString:@"bigbed"];

    if (success) {
        return success;
    }

    success |= [Codec isSupportedPath:path blurb:blurb];
    if (!success) {
        return success;
    }

    if (!success) {
        if (blurb) {
            *blurb = [NSString stringWithFormat:@"%@. unsupported file format", path];
        }
    }

    return success;
}

+ (void)prettyPrintLine:(CGRect)rect blurb:(NSString *)blurb {

    ALog(@"%@ Min-x/Max-x: %.0f %.0f. Width: %.0f", (nil == blurb) ? @"" : blurb, CGRectGetMinX(rect), CGRectGetMaxX(rect), CGRectGetWidth(rect));
}

+ (void)prettyPrintRect:(CGRect)rect blurb:(NSString *)blurb {

    ALog(@"%@ origin %.0f %.0f size %.0f %.0f", (nil == blurb) ? @"" : blurb, CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect));
}

+ (void)prettyPrintSize:(CGSize)size blurb:(NSString *)blurb {

    ALog(@"%@ width %.0f. height %.0f", (nil == blurb) ? @"" : blurb, size.width, size.height);
}

+ (void)prettyPrintCGAffineTransform:(CGAffineTransform)transform blurb:(NSString *)blurb {

    ALog(@"\n%@\na %.2f b %.2f tx %.2f\nc %.2f d %.2f ty %.2f", (nil == blurb) ? @"" : blurb,
    transform.a, transform.b, transform.tx,
    transform.c, transform.d, transform.ty);

}

+ (UIColor *)colorWithCommaSeparateRGBString:(NSString *)rgbString {

    NSArray *rgb = [rgbString componentsSeparatedByString:@","];
    if (nil == rgb || [rgb count] != 3) {
        return nil;
    }

    UIColor *result = [UIColor colorWithRed:[[rgb objectAtIndex:0] floatValue]/255.0
                                      green:[[rgb objectAtIndex:1] floatValue]/255.0
                                       blue:[[rgb objectAtIndex:2] floatValue]/255.0
                                      alpha:1.0];

    return result;
}

+ (BOOL)isValidStatusCode:(NSInteger)statusCode {
    return statusCode >= 200 && statusCode < 300;
}

+ (BOOL)isUsablePath:(NSString *)path blurb:(NSString **)blurb {

    if (![IGVHelpful isReachablePath:path]) {

        if (blurb) {
            *blurb = [NSString stringWithFormat:@"%@ is unreachable", path];
        }

        return NO;
    }

    if (![IGVHelpful isSupportedPath:path blurb:blurb]) {
        return NO;
    }

    return YES;
}

+ (BOOL)isUsableIndexPath:(NSString *)indexPath blurb:(NSString **)blurb {

    NSString *indexPathExtension = [indexPath pathExtension];

    if (![IGVHelpful isReachablePath:indexPath]) {

        if (blurb) {
            *blurb = [NSString stringWithFormat:@"%@ is unreachable", indexPath];
        }

        return NO;
    }

//    if (![IGVHelpful isSupportedPath:indexPath blurb:blurb]) {
//        return NO;
//    }

    return YES;
}

@end
