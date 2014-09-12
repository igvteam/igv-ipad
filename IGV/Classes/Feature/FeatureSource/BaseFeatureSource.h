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
// Created by jrobinso on 8/7/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "FeatureSource.h"

@class FeatureCache;
@class LMResource;
@class FeatureInterval;

static const int MAX_FEATURE_FILE_BYTES = 50000;
static const int MINIMUM_VISIBILITY_WINDOW = 10000;

@interface BaseFeatureSource : NSObject <FeatureSource>
@property(nonatomic, retain) NSMutableDictionary *trackProperties;
@property(nonatomic, retain) NSMutableDictionary *chrTable;
@property(nonatomic, retain) FeatureCache *featureCache;
@property(nonatomic) long long int visibilityWindowThreshold;

- (id)featuresForFeatureInterval:(FeatureInterval *)featureInterval;

- (void)clearFeatureCache;

- (NSArray *)chromosomeNames;

+ (BaseFeatureSource *)featureSourceWithResource:(LMResource *)resource;
@end