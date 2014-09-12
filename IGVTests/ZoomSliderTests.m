//
//  ZoomSliderTests.m
//  IGV
//
//  Created by turner on 1/29/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "Logging.h"
#import "IGVHelpful.h"

@interface ZoomSliderTests : SenTestCase
@end

@implementation ZoomSliderTests

-(void)testInvesionOfLogarithmicScale {

    double min = 0;
    double max = 10;

    NSUInteger howmany = 16;
    for(NSUInteger i = 0; i <= howmany; i++) {

        double alpha = ((double)i)/((double)howmany);
        double value = (1.0 - alpha) * min + alpha * max;

        double linear = (value - min) / (max - min);
        double logarithmic = pow(2, (value - min)) / pow(2, (max - min));
        double derived = log2(logarithmic * pow(2, (max - min))) + min;

        ALog(@"logarithmic %.4f. linear %.4f. value %.4f. derived %.4f. i %d", logarithmic, linear, value, derived, i);
    }

}

-(void)testPlaywithLog2 {

    NSUInteger howmany = 10;

    for(NSUInteger i = 0; i <= howmany; i++) {

        NSNumber *xaxis = [NSNumber numberWithDouble:pow(2, i)];
        NSString *xx  = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:xaxis];

        NSNumber *yaxis = [NSNumber numberWithDouble:log2([xaxis doubleValue])];

        double logarithmic = [xaxis doubleValue]/ pow(2, howmany);
        double linear = ((double)i)/((double)howmany);

        ALog(@"logarithmic %.5f. linear %.5f. n %d. 2^n %@. log2(2^n) %@.", logarithmic, linear, i, xx, yaxis)
    }
}

-(void)testLogScale {

    NSMutableArray *i = [NSMutableArray array];
    NSMutableArray *o = [NSMutableArray array];
    NSMutableArray *deltas = [NSMutableArray array];

    NSUInteger howmany = 32;
    for (NSUInteger x = 0; x < howmany; x++) {
        [i addObject:[NSNumber numberWithDouble:pow(2, x)]];
        [o addObject:[NSNumber numberWithDouble:log2([[i objectAtIndex:x] doubleValue])]];

        double delta;
        if (0 == x) {
            delta = 0;
        } else {
            delta = [[i objectAtIndex:x] doubleValue] - [[i objectAtIndex:(x - 1)] doubleValue];
        }

        [deltas addObject:[NSNumber numberWithDouble:delta]];

    }

    double iScaleFactor = [[i objectAtIndex:(howmany - 1)] doubleValue];
    double oScaleFactor = [[o objectAtIndex:(howmany - 1)] doubleValue];

    for (NSUInteger ii = 0; ii < howmany; ii++) {

        double vi = [[i objectAtIndex:ii] doubleValue]/iScaleFactor;
        double vo = [[o objectAtIndex:ii] doubleValue]/oScaleFactor;

        NSString *si = (vi < 0.5) ? [NSString stringWithFormat:@"---"] : [NSString stringWithFormat:@"+++"];
        NSString *so = (vo < 0.5) ? [NSString stringWithFormat:@"---"] : [NSString stringWithFormat:@"+++"];

        ALog(@"i %@ %.4f. o %@ %.4f.", si, vi, so, vo);
    }


//    for (NSNumber *v in i) {
//        NSString *ii = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:v];
//        NSString *dd = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[deltas objectAtIndex:[i indexOfObject:v]]];
//
//        ALog(@"%@ i delta %@ o %@", ii, dd, [o objectAtIndex:[i indexOfObject:v]]);
//    }

}

@end
