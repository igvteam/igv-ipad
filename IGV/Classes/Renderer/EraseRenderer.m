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
//  Created by turner on 3/27/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "EraseRenderer.h"
#import "FeatureList.h"
#import "Logging.h"
#import "TrackView.h"

@interface EraseRenderer ()
@property(nonatomic, retain) UIColor *eraseColor;
@end

@implementation EraseRenderer

@synthesize eraseColor;

- (void)dealloc {
    self.eraseColor = nil;
    [super dealloc];
}

- (id)init {

    self = [super init];

    if (nil != self) {

        self.eraseColor = [UIColor whiteColor];
    }

    return self;
}

- (id)initWithEraseColor:(UIColor *)aEraseColor {

    self = [super init];

    if (nil != self) {

        self.eraseColor = aEraseColor;
    }

    return self;
}


- (void)renderInRect:(CGRect)rect featureList:(FeatureList *)featureList trackProperties:(NSDictionary *)trackProperties track:(TrackView *)track {

    if (featureList) ALog(@"%@", featureList);

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    [self.eraseColor setFill];
    UIRectFill([TrackView renderSurfaceWithTrackRect:rect]);
}

@end