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
// Created by jrobinso on 7/27/12.
//

#import "LMSession.h"
#import "LMResource.h"
#import "SMXMLDocument.h"

@interface LMSession ()
- (id)initWithDocument:(SMXMLDocument *)document;
- (void)processResources:(SMXMLElement *)resourcesElement;
@end

@implementation LMSession

@synthesize genome;
@synthesize locus;
@synthesize resources;

- (void)dealloc {
    self.genome = nil;
    self.locus = nil;
    self.resources = nil;
    [super dealloc];
}

+ (id)sessionWithPath:(NSString *)path {

    return [[[LMSession alloc] initWithPath:path] autorelease];
}

+ (id) sessionWithDocument:(SMXMLDocument *) document {
    return [[[LMSession alloc] initWithDocument:document] autorelease];
}

- (id)initWithPath:(NSString *)path {
    
    self = [super init];
    
    if (nil != self) {
        
        NSData *xmlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
        if (nil == xmlData) {
            self = nil;
        } else {
            
            NSError *error =  nil;
            SMXMLDocument *smxmlDocument = [SMXMLDocument documentWithData:xmlData error:&error];
            
            if (nil == smxmlDocument) {
                self = nil;
            } else {
                self = [self initWithDocument:smxmlDocument];
            }
        }
    }
    
    return self;
}

- (id)initWithDocument: (SMXMLDocument *)document {

    self = [super init];
    if (nil != self) {

        SMXMLElement *root   = document.root;
        self.genome = [root attributeNamed:@"genome"];
        self.locus = [root attributeNamed:@"locus"];
        self.resources = [NSMutableArray array];

        NSArray *children = root.children;
        for (SMXMLElement *child in children) {

            NSString *tagName = child.name;

            if ([tagName isEqualToString:@"Resources"] ||
                    [tagName isEqualToString:@"Files"]    ) {
                [self processResources:child];

            }
            else {
                // Other tags ignored for now
            }

        }
    }
    return self;
}


- (void)processResources:(SMXMLElement *)resourcesElement {


    NSArray *children = resourcesElement.children;
    for (SMXMLElement *child in children) {

        NSString *tagName = child.name;

        if ([tagName isEqualToString:@"Resource"] || [tagName isEqualToString:@"DataFile"]) {

            LMResource *resource = [LMResource resourceWithElement:child];
            [((NSMutableArray *) resources) addObject:resource];
        }
        else {
            // This should not be possible
        }


    }
}

@end