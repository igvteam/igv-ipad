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


#import "TDFFixedTile.h"
#import "LittleEndianByteBuffer.h"
#import "WIGFeature.h"

@interface TDFFixedTile ()

@property(nonatomic, retain) NSMutableDictionary *featureDictionary;

@end


@implementation TDFFixedTile {

}

@synthesize start;
@synthesize span;
@synthesize featureDictionary;


- (void)dealloc {
    self.featureDictionary = nil;
    [super dealloc];
}


- (TDFFixedTile *)initWithBuffer:(LittleEndianByteBuffer *)les forTracks:(NSArray *)trackNames {

    self = [super init];

    if (nil != self) {

        int trackCount = trackNames.count;
        int featureCount = [les nextInt];
        self.start = [les nextInt];
        self.span = [les nextFloat];

        self.featureDictionary = [NSMutableDictionary dictionaryWithCapacity:trackCount];

        for (int t = 0; t < trackCount; t++) {
            NSMutableArray *features = [NSMutableArray array];

            int featureStart = self.start;
            int featureEnd = (int) ceilf(featureStart + self.span);

            for (int i = 0; i < featureCount; i++) {
                float value = [les nextFloat];
                WIGFeature *feature = [[[WIGFeature alloc] initWithStart:featureStart end:featureEnd score:value] autorelease];
                [features addObject:feature];

                featureStart += self.span;
                featureEnd += self.span;
            }

            NSString *trackName = [trackNames objectAtIndex:t];
            [self.featureDictionary setObject:features forKey:trackName];
        }
    }

    return self;

}

- (NSArray *)featuresForTrack:(NSString *)trackName {
    return [self.featureDictionary objectForKey:trackName];
}


@end