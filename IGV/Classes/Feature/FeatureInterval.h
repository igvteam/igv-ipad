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
// Created by jrobinso on 7/29/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface FeatureInterval : NSObject
- (id)initWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end zoomLevel:(NSInteger)zoomLevel;
@property(nonatomic, copy) NSString *chromosomeName;
@property(nonatomic, assign) long long start;
@property(nonatomic, assign) long long end;
@property(nonatomic, assign) NSInteger zoomLevel;
- (long long int)length;
- (BOOL)containsFeatureInterval:(FeatureInterval *)featureInterval;
- (BOOL)containsChromosomeName:(NSString *)chr start:(long long int)start end:(long long int)end zoomLevel:(NSInteger)zoomLevel;
+ (id)intervalWithChromosomeName:(NSString *)chromosomeName;
+ (id)intervalWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end;
+ (id)intervalWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end zoomLevel:(NSInteger)zoomLevel;
@end