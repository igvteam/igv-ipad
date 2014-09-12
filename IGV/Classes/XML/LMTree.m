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


#import "LMTree.h"
#import "LMCategory.h"
#import "SMXMLDocument.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "Logging.h"
#import "IGVHelpful.h"

@interface LMTree ()
- (id)initWithDocument:(SMXMLDocument *)document;
@end

@implementation LMTree {

@private
}

@synthesize rootCategory;

- (void)dealloc {

    self.rootCategory = nil;
    [super dealloc];
}

+ (id)treeWithPath:(NSString *)path error:(NSError **)error {

    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
    if (!data) {

        if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"Error retrieving data from path %@", path]];
        return nil;
    }

    // Create the document
    SMXMLDocument *document = [SMXMLDocument documentWithData:data error:error] ;

    if (nil == document) {
        if (nil != error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"Error creating SMXMLDocument with data from path %@", path]];
        return nil;
    }

    return [self treeWithDocument:document];
}

+ (id)treeWithDocument:(SMXMLDocument *)document {
    return [[[LMTree alloc] initWithDocument:document] autorelease];
}

- (id)initWithDocument:(SMXMLDocument *)document {
    self = [super init];
    if (self) {
        [self buildTreeWithDocument:document];
    }

    return self;
}

- (void)buildTreeWithDocument:(SMXMLDocument *)document {
    SMXMLElement *root = document.root;
    self.rootCategory = [LMCategory categoryWithElement:root];
}

@end