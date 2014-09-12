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
// Created by jrobinso on 3/24/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FeatureSourceUtils.h"
#import "IGVContext.h"
#import "WIGFeature.h"


@implementation FeatureSourceUtils {

}

// Condense the input features to a resolution suitable for the current zoomLevel level.
//

+ (NSArray *)collapseFeatures:(NSArray *)featureArray startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex {

    NSMutableArray *collapsedFeatures = [NSMutableArray arrayWithCapacity:2000];

    double basesPerPoint = 1.0 / [IGVContext sharedIGVContext].pointsPerBase;

    int currentBucket = -1;
    double currentSum = 0;
    int currentBucketFeatureCount = 0;

    for (int idx = startIndex; idx <= endIndex; idx++) {
        WIGFeature *wigFeature = [featureArray objectAtIndex:idx];

        int startBucket = (int) (wigFeature.start / basesPerPoint);
        int endBucket = (int) (wigFeature.end / basesPerPoint);

        if (endBucket > startBucket) {
            [collapsedFeatures addObject:wigFeature];
        }
        else {
            if (endBucket > currentBucket) {
                if (currentBucketFeatureCount > 0) {
                    float avg = currentSum / currentBucketFeatureCount;
                    int start = (int) (currentBucket * basesPerPoint);
                    int end = (int) ((currentBucket + 1) * basesPerPoint);
                    WIGFeature *f = [[[WIGFeature alloc] initWithStart:start end:end score:avg] autorelease];
                    [collapsedFeatures addObject:f];
                }
                currentSum = 0;
                currentBucketFeatureCount = 0;
            }


            currentBucket = startBucket;
            currentSum += wigFeature.score;
            currentBucketFeatureCount++;

        }
    }
    if (currentBucketFeatureCount > 0) {
        float avg = currentSum / currentBucketFeatureCount;
        int start = (int) (currentBucket * basesPerPoint);
        int end = (int) ((currentBucket + 1) * basesPerPoint);
        WIGFeature *f = [[[WIGFeature alloc] initWithStart:start end:end score:avg] autorelease];
        [collapsedFeatures addObject:f];
    }

    return collapsedFeatures;
}
@end