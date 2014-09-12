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
//  RulerView.m
//  IGV
//
//  Created by turner on 7/15/14.
//
//

#import "RulerView.h"
#import "IGVContext.h"
#import "FeatureInterval.h"
#import "Logging.h"
#import "LocusListItem.h"
#import "UINib-View.h"
#import "IGVMath.h"
#import "IGVHelpful.h"

#define TickSeparationThreshold (50)
//#define TickSeparationThreshold (100)

@interface RulerView ()
@property(nonatomic, retain) UILabel *tickLabel;
@property(nonatomic, retain) NSMutableArray *tickDivisors;
@property(nonatomic, retain) NSMutableArray *tickUnits;
@property(nonatomic, retain) NSMutableArray *tickValues;

- (NSString *)tickLabelStringWithTickLabelNumber:(long long int)tickLabelNumber tickIndex:(NSUInteger)tickIndex igvContextLength:(long long int)igvContextLength;
@end

@implementation RulerView

@synthesize tickLabel = _tickLabel;
@synthesize tickDivisors = _tickDivisors;
@synthesize tickUnits = _tickUnits;
@synthesize tickValues = _tickValues;

- (void)dealloc {

    self.tickLabel = nil;
    self.tickDivisors = nil;
    self.tickUnits = nil;
    self.tickValues = nil;

    [super dealloc];
}

-(UILabel *)tickLabel {

    if (nil == _tickLabel) {
        self.tickLabel = (UILabel *) [UINib containerViewForNibNamed:@"RulerLabel"];
    }

    return _tickLabel;
}

- (NSMutableArray *)tickDivisors {

    if (nil == _tickDivisors) {
        self.tickDivisors = [NSMutableArray array];

        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e6] atIndex:0]; // 1e8
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e6] atIndex:0];  // 5e7
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e6] atIndex:0];  // 1e7
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e6] atIndex:0];  // 5e6
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e6] atIndex:0];  // 1e6

        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e3] atIndex:0];  // 5e5
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e3] atIndex:0];  // 1e5
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e3] atIndex:0];  // 5e4
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e3] atIndex:0]; // 1e4
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e3] atIndex:0]; // 5e3
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1e3] atIndex:0]; // 1e3

        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1] atIndex:0]; // 5e2
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1] atIndex:0]; // 1e2
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1] atIndex:0]; // 5e1
        [self.tickDivisors insertObject:[NSNumber numberWithDouble:1] atIndex:0]; // 1e1

    }

    return _tickDivisors;
}

- (NSMutableArray *)tickUnits {

    if (nil == _tickUnits) {
        self.tickUnits = [NSMutableArray array];

        [self.tickUnits insertObject:@"mb" atIndex:0]; // 1e8
        [self.tickUnits insertObject:@"mb" atIndex:0];  // 5e7
        [self.tickUnits insertObject:@"mb" atIndex:0];  // 1e7
        [self.tickUnits insertObject:@"mb" atIndex:0];  // 5e6
        [self.tickUnits insertObject:@"mb" atIndex:0];  // 1e6

        [self.tickUnits insertObject:@"kb" atIndex:0];  // 5e5
        [self.tickUnits insertObject:@"kb" atIndex:0];  // 1e5
        [self.tickUnits insertObject:@"kb" atIndex:0];  // 5e4
        [self.tickUnits insertObject:@"kb" atIndex:0]; // 1e4
        [self.tickUnits insertObject:@"kb" atIndex:0]; // 5e3
        [self.tickUnits insertObject:@"kb" atIndex:0]; // 1e3

        [self.tickUnits insertObject:@"b" atIndex:0]; // 5e2
        [self.tickUnits insertObject:@"b" atIndex:0]; // 1e2
        [self.tickUnits insertObject:@"b" atIndex:0]; // 5e1
        [self.tickUnits insertObject:@"b" atIndex:0]; // 1e1

    }

    return _tickUnits;
}

- (NSMutableArray *)tickValues {

    if (nil == _tickValues) {
        self.tickValues = [NSMutableArray array];

        [self.tickValues insertObject:[NSNumber numberWithDouble:1e8] atIndex:0]; // 1e8
        [self.tickValues insertObject:[NSNumber numberWithDouble:5e7] atIndex:0];  // 5e7
        [self.tickValues insertObject:[NSNumber numberWithDouble:1e7] atIndex:0];  // 1e7
        [self.tickValues insertObject:[NSNumber numberWithDouble:5e6] atIndex:0];  // 5e6
        [self.tickValues insertObject:[NSNumber numberWithDouble:1e6] atIndex:0];  // 1e6
        [self.tickValues insertObject:[NSNumber numberWithDouble:5e5] atIndex:0];  // 5e5
        [self.tickValues insertObject:[NSNumber numberWithDouble:1e5] atIndex:0];  // 1e5
        [self.tickValues insertObject:[NSNumber numberWithDouble:5e4] atIndex:0];  // 5e4
        [self.tickValues insertObject:[NSNumber numberWithDouble:1e4] atIndex:0]; // 1e4
        [self.tickValues insertObject:[NSNumber numberWithDouble:5e3] atIndex:0]; // 5e3
        [self.tickValues insertObject:[NSNumber numberWithDouble:1e3] atIndex:0]; // 1e3
        [self.tickValues insertObject:[NSNumber numberWithDouble:5e2] atIndex:0]; // 5e2
        [self.tickValues insertObject:[NSNumber numberWithDouble:1e2] atIndex:0]; // 1e2
        [self.tickValues insertObject:[NSNumber numberWithDouble:5e1] atIndex:0]; // 5e1
        [self.tickValues insertObject:[NSNumber numberWithDouble:1e1] atIndex:0]; // 1e1

    }

    return _tickValues;
}

- (void)drawRect:(CGRect)rect {

    IGVContext *igvContext = [IGVContext sharedIGVContext];
    if (!igvContext) {
        [super drawRect:rect];
        return;
    }

    FeatureInterval *featureInterval = [igvContext currentFeatureInterval];
    if (!featureInterval) {
        [super drawRect:rect];
        return;
    }

    double basesPerPoint = 1.0 / [[IGVContext sharedIGVContext] pointsPerBase];
    double igvContextLengthPoints = floor([igvContext length] / basesPerPoint);
    NSString *igvContextLengthPointsString = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithDouble:igvContextLengthPoints]];

    NSString *locusListItemLengthBases =   [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[[igvContext currentLocusListItem] length]]];
    NSString *igvContextLengthBases =      [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[igvContext length]]];
    NSString *featureIntervalLengthBases = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[igvContext currentFeatureInterval].length]];
    NSString *rectLengthBases =            [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithDouble:floor(CGRectGetWidth(rect) * basesPerPoint)]];

    long long int incrementPoints = 0;
    NSUInteger index = 0;
    for (NSNumber *tickValue in self.tickValues) {

        incrementPoints = (long long int)floor([tickValue doubleValue] / basesPerPoint);
        if (incrementPoints > TickSeparationThreshold) {

            index = [self.tickValues indexOfObject:tickValue];

            NSString *tickUnit = [self.tickUnits objectAtIndex:index];
            NSString *tickDivisor = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[self.tickDivisors objectAtIndex:index]];
            break;
        }
    }

    NSNumber *tickValue = [self.tickValues objectAtIndex:index];
    long long int tickLabelNumber = igvContext.start;
    self.tickLabel.text = [self tickLabelStringWithTickLabelNumber:tickLabelNumber tickIndex:index igvContextLength:[igvContext length]];
    NSUInteger toggle;
    long long int x;
    for (x = 0, toggle = 0; x < igvContextLengthPoints; x += incrementPoints, toggle++) {

        CGSize tickLabelSize = [self.tickLabel.text sizeWithAttributes:[NSDictionary dictionaryWithObject:self.tickLabel.font forKey:NSFontAttributeName]];

        if (/*incrementPoints > tickLabelSize.width ||*/ toggle % 2) {

            [self.tickLabel.text drawInRect:[IGVMath rectWithCenter:CGPointMake(x, CGRectGetHeight(rect) - (tickLabelSize.height / 2.0)) size:tickLabelSize]
                             withAttributes:[NSDictionary dictionaryWithObject:self.tickLabel.font forKey:NSFontAttributeName]];

        }

        UIRectFill(CGRectMake(x, CGRectGetMinY(rect), 1, CGRectGetHeight(rect) - tickLabelSize.height));

        tickLabelNumber += [tickValue longLongValue];

        self.tickLabel.text = [self tickLabelStringWithTickLabelNumber:tickLabelNumber tickIndex:index igvContextLength:[igvContext length]];

    }

}

- (NSString *)tickLabelStringWithTickLabelNumber:(long long int)tickLabelNumber tickIndex:(NSUInteger)tickIndex igvContextLength:(long long int)igvContextLength {

//    ALog(@"length %@", [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:igvContextLength]]);

    NSString *tickUnit = [self.tickUnits objectAtIndex:tickIndex];
    long long int tickDivisor = [[self.tickDivisors objectAtIndex:tickIndex] longLongValue];

    if (igvContextLength > 1e3) {
        tickUnit = @"kb";
        tickDivisor = (long long int)1e3;
    }

    if (igvContextLength > 4e7) {
        tickUnit = @"mb";
        tickDivisor = (long long int)1e6;
    }

    NSString *tickLabelNumberString = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:tickLabelNumber / tickDivisor]];

    return [NSString stringWithFormat:@"%@ %@", tickLabelNumberString, tickUnit];
}

@end
