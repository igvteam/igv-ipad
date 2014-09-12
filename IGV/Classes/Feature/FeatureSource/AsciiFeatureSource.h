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
//  FeatureSource.h
//  IGV
//
//  Created by Douglass Turner on 5/11/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthenticationController.h"
#import "FeatureSource.h"
#import "BaseFeatureSource.h"

@class Codec;
@class TrackController;
@class FeatureList;
@class LinearIndex;
@class FeatureCache;
@class FeatureInterval;
@class BWTotalSummary;


@interface AsciiFeatureSource : BaseFeatureSource <FeatureSource>
- (id)initWithPath:(NSString *)path;
@property(nonatomic, retain) NSMutableDictionary *trackProperties;
@property(nonatomic, retain) LinearIndex *featureIndex;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, retain) Codec *codec;
@property(nonatomic, retain) BWTotalSummary *bwTotalSummary;
@property(nonatomic) int indexLoadAttempts;

- (void)loadFeaturesForInterval:(FeatureInterval *)interval completion:(LoadFeaturesCompletion)completion;
+ (AsciiFeatureSource *)featureSourceForPath:(NSString *)path;
@end


