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
// Created by jrobinso on 7/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "TDFBedTile.h"
#import "LittleEndianByteBuffer.h"
#import "WIGFeature.h"

@interface TDFBedTile()

@property(nonatomic, retain) NSMutableDictionary *featureDictionary;

@end

@implementation TDFBedTile {

}

@synthesize start;
@synthesize featureDictionary;



- (void)dealloc {
    self.featureDictionary = nil;
    [super dealloc];
}

- (TDFBedTile *)initWithBuffer:(LittleEndianByteBuffer *)les forTracks:(NSArray *)trackNames {

    self = [super init];

    if (nil != self) {

        int trackCount = trackNames.count;

        int featureCount = [les nextInt];

        int *startArray = malloc(featureCount * (sizeof(int)));
        
        for (int i = 0; i < featureCount; i++) {
            
            startArray[i] = [les nextInt];
            
            if (0 == i) {
                self.start = startArray[0];
            }
        }

        int *endArray = malloc(featureCount * (sizeof(int)));
        for (int i = 0; i < featureCount; i++) {
            endArray[i] = [les nextInt];
        }

        int nS = [les nextInt];
        assert(nS == trackCount);

        self.featureDictionary = [NSMutableDictionary dictionaryWithCapacity:trackCount];

        for (int t = 0; t < trackCount; t++) {
            NSMutableArray *featureArray = [NSMutableArray arrayWithCapacity:featureCount];
            for (int i = 0; i < featureCount; i++) {
                int featureStart = startArray[i];
                int featureEnd = endArray[i];
                float value = [les nextFloat];
                WIGFeature *feature = [[[WIGFeature alloc] initWithStart:featureStart end:featureEnd score:value] autorelease];
                [featureArray addObject:feature];
            }

            NSString *trackName = [trackNames objectAtIndex:t];
            [self.featureDictionary setObject:featureArray forKey:trackName];
        }

        // Optionally read feature names.  Not sure this is every used
//        NSMutableArray *featureNames = nil;
//        if (includeNames) {
//            featureNames = [NSMutableArray arrayWithCapacity:featureCount];
//            for (int i = 0; i < featureCount; i++) {
//                NSString *nm = [les nextString];
//                [featureNames addObject:nm];
//            }
//        }



        free(startArray);
        free(endArray);
    }

    return self;

}

- (NSArray *)featuresForTrack:(NSString *)trackName {
    return [self.featureDictionary objectForKey:trackName];
}


@end