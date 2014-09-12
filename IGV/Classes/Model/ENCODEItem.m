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
// Created by turner on 1/23/14.
//

#import "ENCODEItem.h"

@implementation ENCODEItem

@synthesize path = _path;
@synthesize cell = _cell;
@synthesize dataType = _dataType;
@synthesize antibody = _antibody;
@synthesize view = _view;
@synthesize replicate = _replicate;
@synthesize type = _type;
@synthesize lab = _lab;
@synthesize enabled = _enabled;
@synthesize line = _line;

- (void)dealloc {

    self.path = nil;
    self.cell = nil;
    self.dataType = nil;
    self.antibody = nil;
    self.view = nil;
    self.replicate = nil;
    self.type = nil;
    self.lab = nil;
    self.line = nil;

    [super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {

    self = [super init];
    if (nil != self) {

        self.enabled = NO;
        self.path = [dictionary objectForKey:@"path"];
        self.cell = [dictionary objectForKey:@"cell"];
        self.dataType = [dictionary objectForKey:@"dataType"];

        self.antibody = [dictionary objectForKey:@"antibody"];
        self.view = [dictionary objectForKey:@"view"];
        self.replicate = [dictionary objectForKey:@"replicate"];

        self.type = [dictionary objectForKey:@"type"];
        self.lab = [dictionary objectForKey:@"lab"];

        // Create and UNORDERED string concatenation of all values.
        // Separate values by '#'
        self.line = @"";
        for (NSString *key in [dictionary allKeys]) {

            if ([key isEqualToString:@"hub"]) {
                continue;
            }

            NSString *obj = [dictionary objectForKey:key];
            self.line = [self.line stringByAppendingFormat:@"%@#", obj];
        }

    }

    return self;
}

- (NSString *)description {

    return [NSString stringWithFormat:@"cell %@ dataType %@ antibody %@ view %@ replicate %@ type %@ lab %@",
                    self.cell, self.dataType, self.antibody, self.view, self.replicate, self.type, self.lab];
}

@end

