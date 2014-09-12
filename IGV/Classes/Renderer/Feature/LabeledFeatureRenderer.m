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
//  Created by turner on 3/20/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "LabeledFeatureRenderer.h"
#import "UINib-View.h"
#import "FeatureList.h"
#import "LabeledFeature.h"
#import "IGVHelpful.h"
#import "IGVMath.h"
#import "UIColor+Random.h"
#import "TrackView.h"
#import "IGVContext.h"

@implementation LabeledFeatureRenderer

@synthesize featureLabel;
@synthesize labelBBoxList;

- (void) dealloc {

    self.featureLabel = nil;
    self.labelBBoxList = nil;

    [super dealloc];
}

-(NSMutableArray *)labelBBoxList {

    if (nil == labelBBoxList) {
        self.labelBBoxList = [NSMutableArray array];
    }

    return labelBBoxList;
}

-(UILabel *)featureLabel {

    if (nil == featureLabel) {
        self.featureLabel = (UILabel *) [UINib containerViewForNibNamed:@"BEDTrackLabel"];
    }

    return featureLabel;
}

- (void)renderInRect:(CGRect)rect featureList:(FeatureList *)featureList trackProperties:(NSDictionary *)trackProperties track:(TrackView *)track {

    if (nil == featureList) {
        return;
    }

    [self.labelBBoxList removeAllObjects];

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    [[UIColor whiteColor] setFill];
    CGRect renderSurface = [TrackView renderSurfaceWithTrackRect:rect];
    UIRectFill(renderSurface);

    [[UIColor whiteColor] setFill];
    CGRect dataSurface = [TrackView dataSurfaceWithTrack:track];
    UIRectFill(dataSurface);

    CGContextSetLineWidth( UIGraphicsGetCurrentContext(), 2);

    double pointsPerBase = (CGFloat) [[IGVContext sharedIGVContext] pointsPerBase];

    for (LabeledFeature *labeledFeature in featureList.features) {

        // east trivial rejection test: [feature start]
        if (labeledFeature.start > [IGVContext sharedIGVContext].end) {
            break; // We're done
        }
        // west trivial rejection test: [feature start] + [feature length]
        if ((labeledFeature.end) < [IGVContext sharedIGVContext].start) {
            continue;
        }

        CGRect featureSurface = [LabeledFeatureRenderer featureTileForFeature:labeledFeature
                                                                  dataSurface:dataSurface
                                                                   labelFrame:self.featureLabel.frame
                                                                pointsPerBase:pointsPerBase];

        [[FeatureRenderer tileColor] setFill];
        UIRectFill(featureSurface);
//        [IGVHelpful prettyPrintRect:featureSurface blurb:[NSString stringWithFormat:@"%@", [LabeledFeatureRenderer class]]];

        [self featureLabelWithLabelTemplate:self.featureLabel
                             featureSurface:featureSurface
                                    feature:labeledFeature
                                labelBBoxes:self.labelBBoxList];
    }

}

- (void)featureLabelWithLabelTemplate:(UILabel *)labelTemplate
                       featureSurface:(CGRect)featureSurface
                              feature:(LabeledFeature *)feature
                          labelBBoxes:(NSMutableArray *)aLabelBBoxes {


    labelTemplate.text = (nil == feature.label) ? @"" : feature.label;
    [labelTemplate sizeToFit];

    CGRect fr = labelTemplate.frame;

    fr.origin.x = CGRectGetMidX(featureSurface) - CGRectGetMidX(labelTemplate.bounds);
    fr.origin.y = CGRectGetMaxY(featureSurface);

    labelTemplate.frame = fr;

    for (NSValue *rectValue in aLabelBBoxes) {

        // do not render label if it overlaps a pre-existing label bbox
        if (CGRectIntersectsRect(labelTemplate.frame, [rectValue CGRectValue])) {
            return;
        }
    }

    [aLabelBBoxes addObject:[NSValue valueWithCGRect:labelTemplate.frame]];

//    [[UIColor randomRGBWithAlpha:.75] setFill];
//    UIRectFill([IGVMath rectWithOrigin:label.frame.origin size:[[feature label] sizeWithFont:label.font]]);


    [labelTemplate.textColor setFill];

    CGSize size = [[feature label] sizeWithAttributes:[NSDictionary dictionaryWithObject:labelTemplate.font forKey:NSFontAttributeName]];
//    [[feature label] drawInRect:[IGVMath rectWithOrigin:labelTemplate.frame.origin size:size] withFont:labelTemplate.font];
    [[feature label] drawInRect:[IGVMath rectWithOrigin:labelTemplate.frame.origin size:size] withAttributes:[NSDictionary dictionaryWithObject:labelTemplate.font forKey:NSFontAttributeName]];

}

+ (CGRect)featureTileForFeature:(LabeledFeature *)feature dataSurface:(CGRect)dataSurface labelFrame:(CGRect)labelFrame pointsPerBase:(double)pointsPerBase {

    CGRect featureTile = [super featureBounds:feature dataSurface:dataSurface pointsPerBase:pointsPerBase];

    // reduce height to allow room for label
    featureTile.size.height = CGRectGetHeight(featureTile) - CGRectGetHeight(labelFrame);

    return featureTile;
}

+ (UIColor *)lineColor {

    // IGV Desktop blue
    return [UIColor colorWithRed:0 green:0 blue:150.0/255.0 alpha:1.0];
}

+ (UIColor *)arrowHeadColor {

    // IGV Desktop blue
    return [UIColor colorWithRed:0 green:0 blue:150.0/255.0 alpha:1.0];
}

@end