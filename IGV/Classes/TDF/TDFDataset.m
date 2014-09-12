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


#import "TDFDataset.h"
#import "LittleEndianByteBuffer.h"
#import "TDFReader.h"

@interface  TDFDataset()
@property(nonatomic, copy) NSString *dataType;
@end

@implementation TDFDataset {
    NSString *dataType;
}

@synthesize tilePositions;
@synthesize tileSizes;
@synthesize tileWidth;
@synthesize reader;
@synthesize dataType;
@synthesize tileCount;

- (void)dealloc {

    free(tilePositions);
    free(tileSizes);

    self.reader = nil;
    [dataType release];
    [super dealloc];
}

+ (TDFDataset *)datasetWithName:(NSString *)aName data:(NSData *)data reader:(TDFReader *)reader {

    TDFDataset *instance = [[[[self class] alloc] init] autorelease];
    if (nil != instance) {
        [instance fillWithData:data];
        instance.name = aName;
        instance.reader = reader;
    }

    return instance;

}

- (void)fillWithData:(NSData *)data {

    LittleEndianByteBuffer *les = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    [super readAttributes:les];

    self.dataType = [les nextString];
    self.tileWidth = [les nextFloat];

    tileCount = [les nextInt];
    self.tilePositions = malloc((size_t) (tileCount * sizeof(long long)));
    self.tileSizes     = malloc((size_t) (tileCount * sizeof(int)));

    for (int i = 0; i < tileCount; i++) {
        self.tilePositions[i] = [les nextLong];
        self.tileSizes[i]     = [les nextInt];
    }

}


//- (NSArray *) tilesForChromosome: (NSString *) chr zoomLevel: (NSInteger) zoomLevel windowFunction: (NSString *) windowFunction {
//    TDFDataset *dataset = [self.reader datasetForChromosome: chr zoomLevel: zoomLevel windowFunction: windowFunction];
//    float tileWidth = dataset.tileWidth;
//    NSInteger startTile = (NSInteger) floor(startLocation / tileWidth);
//    NSInteger endTile = (NSInteger) floor(endLocation / tileWidth);
//
//    FeatureList *featureList = [[[FeatureList alloc] initForCapacity: 2000] autorelease];
//    for (int t = startTile; t <= endTile; t++) {
//        id<TDFTile> tile = [reader tileForDataset: dataset number: t];
//        if (nil != tile) {
//            [featureList.features addObjectsFromArray: [tile featuresForTrack:<#(NSString *)sampleName#>];
//        }
//    }
//
//}


@end