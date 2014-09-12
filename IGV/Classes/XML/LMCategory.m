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
// Created by jrobinso on 7/26/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LMCategory.h"
#import "LMResource.h"
#import "SMXMLDocument.h"
#import "Logging.h"


@interface LMCategory ()
- (id)initWithElement:(SMXMLElement *)element;

- (NSString *)descriptionWithIndent:(NSString *)indent;


@end

@implementation LMCategory {

}
@synthesize name;
@synthesize childCategories;
@synthesize resources;
@synthesize canCull = _canCull;


- (void)dealloc {
    self.name = nil;
    self.childCategories = nil;
    self.resources = nil;
    [super dealloc];
}

+ (id)categoryWithElement:(SMXMLElement *)element {
    return [[[LMCategory alloc] initWithElement:element] autorelease];
}

- (NSMutableArray *)resourceTreeControllerItems {
    NSMutableArray *combined = [NSMutableArray arrayWithArray:self.childCategories];
    [combined addObjectsFromArray:self.resources];
    return combined;
}


//  <Category name="Broad Histone" trackLine="viewLimits=0:25">
//   <Resource path="http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalGm12878Control.tdf" name="GM12878 Input" trackLine="viewLimits=0:25"/>

- (id)initWithElement:(SMXMLElement *)element {

    self = [super init];

    if (nil != self) {

        self.canCull = YES;

        self.name = [element attributeNamed:@"name"];
        self.childCategories    = [NSMutableArray array];
        self.resources          = [NSMutableArray array];

        NSArray *children = element.children;
        for (SMXMLElement *child in children) {

            NSString *tagName = child.name;

            if ([tagName isEqualToString:@"Category"]) {

                LMCategory *category = [LMCategory categoryWithElement:child];
                [self.childCategories addObject:category];

            } else if ([tagName isEqualToString:@"Resource"]) {

                // Hacky filter
                NSString *path = [child attributeNamed:@"path"];
                if (path != nil && ([path hasSuffix:@"bam"] || [path hasSuffix:@"seg.gz"] || [path hasSuffix:@"seg"] || [path hasSuffix:@"bed"] || [path hasSuffix:@"bed.gz"] ||
                        [path hasSuffix:@"wig"] || [path hasSuffix:@"wig.gz"] || [path hasSuffix:@"tdf"])) {

                    LMResource *resource = [LMResource resourceWithElement:child];
                    [self.resources addObject:resource];
                }

            } else {
                // Should never get here
            }

        }

    }
    return self;
}

- (void)cullChildCategories {

    if (0 == [self.childCategories count]) {

        return;
    }

    NSMutableArray *culled = [NSMutableArray array];
    for (LMCategory *category in self.childCategories) {

        if (category.canCull) [culled   addObject:category];
        else                         [category cullChildCategories];

    }

    [self.childCategories removeObjectsInArray:culled];
}

- (void)cullAssessment {

    if ([self.resources count] > 0) {
        
        self.canCull = NO;
        return;
    } 

    if (0 == [self.childCategories count]) {

        return;
    }

    BOOL b = YES;
    for (LMCategory *category in self.childCategories) {

        [category cullAssessment];
        b = (b && category.canCull);
    }

    self.canCull = b;
}

- (NSString *)description {

    return [NSString stringWithFormat:@"\n%@", [self descriptionWithIndent:@""]];
}

- (NSString *)descriptionWithIndent:(NSString *)indent {

    NSMutableString *string = [NSMutableString string];

    [string appendFormat:@"%@%@(%@)%@child-categories(%d) resources(%d)",
                    indent,
                    [self class],
                    self.name,
                    self.canCull ? @" *CULL* " : @"",
                    [self.childCategories count],
                    [self.resources count]];

    if ([self.childCategories count] > 0) {

        [string appendString:@"\n"];

        NSString *childIndent = [indent stringByAppendingString:@"  "];
        for (LMCategory *category in self.childCategories) [string appendFormat:@"%@\n", [category descriptionWithIndent:childIndent]];

    }

    return string;
}
@end