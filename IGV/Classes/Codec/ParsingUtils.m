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
// Created by jrobinso on 7/24/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "ParsingUtils.h"
#import "DataScale.h"
#import "IGVHelpful.h"

@interface ParsingUtils ()
+ (UIColor *)colorWithRGBString:(NSString *)rgbString;
@end

@implementation ParsingUtils

// See http://stackoverflow.com/questions/3200521/cocoa-trim-all-leading-whitespace-from-nsstring
+ (NSString *)trimWhitespace:(NSString *)aString {
    NSMutableString *mStr = [aString mutableCopy];
    CFStringTrimWhitespace((CFMutableStringRef) mStr);
    NSString *result = [mStr copy];
    [mStr release];
    return [result autorelease];
}

+ (NSMutableDictionary *)parseTrackLine:(NSString *)line {

    NSMutableDictionary *trackProperties = [NSMutableDictionary dictionary];

    // Refer to: http://www.broadinstitute.org/software/igv/TrackLine for details
    NSRegularExpression *trackLinesRegEx = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)=([.:,\"\\w]+)" options:NSRegularExpressionCaseInsensitive error:nil];

    [trackLinesRegEx enumerateMatchesInString:line options:0 range:NSMakeRange(0, [line length]) usingBlock:
            ^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {

                NSString *value = [line substringWithRange:[match rangeAtIndex:2]];
                NSString *key = [line substringWithRange:[match rangeAtIndex:1]];

                if ([key isEqualToString:@"color"]) {

                    UIColor *color = [ParsingUtils colorWithRGBString:value];

                    [trackProperties setObject:color forKey:@"color"];

                } else if ([key isEqualToString:@"name"]) {

                    NSMutableString *raw = [NSMutableString stringWithString:value];
                    [raw replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [raw length])];

                    [trackProperties setObject:raw forKey:@"name"];

                } else if ([key isEqualToString:@"viewLimits"]) {

                    NSArray *parts = [value componentsSeparatedByString:@":"];

                    if (parts.count > 1) {
                        float lowerValue = [[parts objectAtIndex:0] floatValue];
                        float upperValue = [[parts objectAtIndex:1] floatValue];
                        DataScale *scale = [[[DataScale alloc] initWithMin:lowerValue max:upperValue] autorelease];
                        [trackProperties setObject:scale forKey:@"viewLimits"];
                    }

                } else {

                    [trackProperties setObject:value forKey:key];
                }

            }
    ];

    return trackProperties;
}

+ (UIColor *)colorWithRGBString:(NSString *)rgbString {

    NSArray *rgb = [rgbString componentsSeparatedByString:@","];
    return [UIColor colorWithRed:[[rgb objectAtIndex:0] floatValue] / 255.0 green:[[rgb objectAtIndex:1] floatValue] / 255.0 blue:[[rgb objectAtIndex:2] floatValue] / 255.0 alpha:1];
}

@end