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
//  Created by turner on 2/8/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "NSString+FileURLAndLocusParsing.h"

@interface LocusListItem : NSObject

- (id)initWithLocus:(NSString *)locus label:(NSString *)label locusListFormat:(LocusListFormat)locusListFormat genomeName:(NSString *)genomeName;

@property(nonatomic) LocusListFormat locusListFormat;
@property(nonatomic, retain) NSString *chromosomeName;
@property(nonatomic, assign) long long start;
@property(nonatomic, assign) long long end;
@property(nonatomic, retain) NSString *label;
@property(nonatomic, retain) NSString *locus;
@property(nonatomic, copy) NSString *genome;

- (long long int)length;
- (long long int)centroid;

- (LocusListItem *)locusListItemWithScaleFactor:(CGFloat)scaleFactor;
- (LocusListItem *)locusListItemWithLength:(long long int)length;
+ (LocusListItem *)locusWithChromosome:(NSString *)chromosome centroid:(long long int)centroid length:(long long int)length genomeName:(NSString *)genomeName;
+ (LocusListItem *)locusWithChromosome:(NSString *)chromosome centroid:(long long int)centroid halfWidth:(long long int)halfWidth genomeName:(NSString *)genomeName;

- (NSString *)tableViewCellLabel;
- (NSString *)tableViewCellLocus;
- (NSDictionary *)locusListDefaultsItem;
- (NSString *)userDefaultsKey;

+ (NSString *)locusWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem;

- (LocusListItem *)locusListItemWithCentroidPercentage:(CGFloat)centroidPercentage;

+ (NSString *)genomeWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem;
+ (NSString *)labelWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem;

+ (LocusListItem *)locusListItemWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end genomeName:(NSString *)genomeName;
@end