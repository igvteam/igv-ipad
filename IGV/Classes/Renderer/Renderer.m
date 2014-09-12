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
//  Created by turner on 3/16/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Renderer.h"
#import "Logging.h"
#import "FeatureList.h"
#import "Feature.h"
#import "FeatureInterval.h"

@implementation Renderer

- (void)renderInRect:(CGRect)context
         featureList:(FeatureList *)featureList
     trackProperties:(NSDictionary *)trackProperties
               track:(TrackView *)track {

    ALog(@"%@ does not implement this method", [self class]);
}

- (void)renderInRect:(CGRect)rect
          sampleRows:(NSDictionary *)sampleRows
         sampleNames:(NSArray *)sampleNames {

    ALog(@"%@ does not implement this method", [self class]);
}

+ (void)calculateStartIndex:(NSInteger *)startIndex
                   endIndex:(NSInteger *)endIndex
                featureList:(FeatureList *)featureList
     currentFeatureInterval:(FeatureInterval *)currentFeatureInterval {

    *startIndex = 0;
    *endIndex = [featureList.features count] - 1;

    int index = 0;
    for (Feature *feature in featureList.features) {

        if (feature.end > currentFeatureInterval.start && startIndex == 0) {
            *startIndex = index;
        }

        if (feature.start > currentFeatureInterval.end) {
            *endIndex = index;
            break;
        }

        ++index;
    }
}

@end
