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
// Created by jrobinso on 7/18/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "FeatureSource.h"
#import "URLDataLoader.h"

extern int const GZIP_FLAG;

@class LittleEndianByteBuffer;
@class TDFDataset;
@class TDFGroup;
@class HttpResponse;
@protocol TDFTile;

@interface TDFReader : NSObject

- (TDFReader *)initWithPath:(NSString *)path completion:(HTTPRequestCompletion)completion;
- (TDFReader *)initWithPath:(NSString *)aPath;

@property(nonatomic, retain) NSString *path;
@property(nonatomic, assign) NSInteger version;
@property(nonatomic, assign) BOOL compressed;
@property(nonatomic, retain) NSString *trackLine;
@property(nonatomic, retain) NSString *trackType;
@property(nonatomic, retain) NSMutableArray *trackNames;
@property(nonatomic, retain) NSMutableDictionary *datasetIndex;
@property(nonatomic, retain) NSMutableDictionary *groupIndex;
@property(nonatomic, retain) NSMutableSet *chromosomeNames;

//- (void)groupWithName:(NSString *)name completion:(HTTPRequestCompletion)completion;

- (TDFDataset *)loadDatasetForChromosome:(NSString *)chromosome zoom:(NSInteger)zoom windowFunction:(NSString *)windowFunction error:(NSError **)error;
- (id)tileForDataset:(TDFDataset *)dataset number:(NSInteger)tileNumber;
- (void)parseHeaderDataWithLittleEndianByteBuffer:(LittleEndianByteBuffer *)littleEndianByteBuffer;
- (void)parseMasterIndexWithLittleEndianByteBuffer:(LittleEndianByteBuffer *)littleEndianByteBuffer;
@end