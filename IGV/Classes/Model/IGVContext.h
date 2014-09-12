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
//  IGVContext.h
//  InfiniteScroll
//
//  Created by Douglass Turner on 12/25/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RootContentController.h"

@class Cytoband;
@class RootScrollView;
@class LocusListItem;
@class FeatureInterval;

@interface IGVContext : NSObject
@property(nonatomic, retain) NSString *chromosomeName;
@property(nonatomic) long long start;
@property(nonatomic) long long end;
@property(nonatomic, retain) NSMutableDictionary *nucleotideLetterLabels;
- (NSInteger)zoomLevel;
- (CGFloat)chromosomeZoomWithLocusListItem:(LocusListItem *)locusListItem;
- (long long int)length;
- (double) pointsPerBase;
- (NSString *)currentLocus;
- (LocusListItem *)currentLocusListItem;
- (FeatureInterval *)currentFeatureInterval;
- (void)setWithLocusStart:(long long int)locusStart locusEnd:(long long int)locusEnd locusOffsetComparisonBases:(double *)locusOffsetComparisonBases;
+ (IGVContext *)sharedIGVContext;
@end
