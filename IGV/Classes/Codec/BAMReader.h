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
//  BAMReader.h
//
//  Created by James Robinson on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "sam.h"
#import "Codec.h"

@class Cytoband;
@class AlignmentResults;
@class IGVContext;
@class FeatureInterval;

@interface  BAMReader : NSObject
- (id)initWithPath:(NSString *)path;
@property(nonatomic, retain) NSMutableArray *chromosomeNames;
@property(nonatomic, retain) NSMutableDictionary *chrLookupTable;
- (AlignmentResults *)fetchAlignmentsWithFeatureInterval:(FeatureInterval *)featureInterval error:(NSError **)error;
@end
