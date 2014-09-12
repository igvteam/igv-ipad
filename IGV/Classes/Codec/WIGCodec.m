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
// Created by jrobinso on 5/9/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "WIGCodec.h"
#import "WIGFeature.h"
#import "IGVHelpful.h"
#import "IGVContext.h"
#import "GenomeManager.h"
#import "Logging.h"

@interface WIGCodec ()
@property(nonatomic) NSUInteger stepOffset;
@property(nonatomic, copy) NSString *chromosome;
@property(nonatomic) NSInteger step;
@property(nonatomic) NSInteger span;
@property(nonatomic) NSInteger format;
@property(nonatomic) NSInteger start;

- (void)parseStepLine:(NSArray *)aTokens error:(NSError **)error;
- (WIGFeature *)createFeatureWithTokens:(NSArray *)tokens error:(NSError **)error;
@end

NSString *const kVariableStepFormat = @"variableStep";
NSString *const kFixedStepFormat = @"fixedStep";

NSString *const kStepFormatKey = @"stepFormat";
NSString *const kChromosomeKey = @"chrom";
NSString *const kStartKey = @"start";
NSString *const kStepKey = @"step";
NSString *const kSpanKey = @"span";

NSInteger FIXED_STEP = 0;
NSInteger VARIABLE_STEP = 1;

@implementation WIGCodec

@synthesize chromosome = _chromosome;
@synthesize stepOffset = _stepOffset;
@synthesize step = _step;
@synthesize span = _span;
@synthesize format = _format;

- (void)dealloc {

    self.chromosome = nil;
    [super dealloc];
}

- (id)init {

    self = [super init];

    if (nil != self) {

        self.stepOffset = 0;
        self.span = 1;
        self.step = 1;

    }

    return self;
}

- (Feature *)decodeLine:(NSString *)aLine chromosome:(NSString **)chromosome error:(NSError **)error {

    NSMutableArray *tokens = [NSMutableArray arrayWithArray:[aLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];

    if (tokens.count == 0) {
        return nil;
    }

    NSString *firstToken = [tokens objectAtIndex:0];

    // TODO -- handle bedgraph option
    if ([firstToken isEqualToString:kVariableStepFormat] || [firstToken isEqualToString:kFixedStepFormat]) {

        [self parseStepLine:tokens error:error];
        return nil;
    } else {

        *chromosome = self.chromosome;
        WIGFeature *feature = [self createFeatureWithTokens:tokens error:error];

        if (nil == feature) {
            return nil;
        }

        self.stepOffset += 1;

        return feature;
    }

}

- (void)parseStepLine:(NSArray *)aTokens error:(NSError **)error {

    for (NSString *token in aTokens) {

        // step format
        if ([token isEqualToString:kFixedStepFormat]) {

            self.format = FIXED_STEP;

            continue;
        }

        if ([token isEqualToString:kVariableStepFormat]) {

            self.format = VARIABLE_STEP;

            continue;
        }


        NSArray *parts = [token componentsSeparatedByString:@"="];

        if ([parts count] == 2) {

            NSString *key = [parts objectAtIndex:0];
            NSString *value = [parts objectAtIndex:1];

            // chromosomeName name
            if ([key isEqualToString:kChromosomeKey]) {

                NSString *chr = [[GenomeManager sharedGenomeManager] chromosomeAliasForString:value];
                if (nil == [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:chr]) {
                    if (*error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"Bogus chromosomeName name %@", value]];
                    return;
                }

                self.chromosome = chr;
            }

            else if ([key isEqualToString:kStartKey]) {

                self.start = [value integerValue] - 1;    // Wig formats are "1" based
                self.stepOffset = 0;
            }

            else if ([key isEqualToString:kStepKey]) {

                self.step = [value integerValue];
            }

            else if ([key isEqualToString:kSpanKey]) {

                self.span = [value integerValue];
            }

        }
    }

}

- (WIGFeature *)createFeatureWithTokens:(NSArray *)tokens error:(NSError **)error {

    long long int start = 0;
    long long int  end = 0;
    CGFloat score;

    if (self.format == VARIABLE_STEP) {

        if (tokens.count < 2) {
            if (*error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. token count %d < 2", [self class], tokens.count]];
            return nil;
        }

        start = [[tokens objectAtIndex:0] integerValue] - 1;   // Wig is "1" based
        end = start + self.span;
        score = [[tokens objectAtIndex:1] floatValue];

    } else {  // Assumption is fixed step

        if (tokens.count < 1) {
            if (*error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. token count %d < 1", [self class], tokens.count]];
            return nil;
        }

        start = (self.stepOffset * self.step) + self.start;
        end = start + self.span;
        score = [[tokens objectAtIndex:0] floatValue];
    }

    WIGFeature *wigFeature = [[[WIGFeature alloc] initWithStart:start end:end score:score] autorelease];

    return wigFeature;
}

+ (NSString *)fileSuffixKey {
    return @"wig";
}

@end