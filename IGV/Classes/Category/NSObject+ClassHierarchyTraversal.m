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
//  NSObject+ClassHierarchyTraversal.m
//  IGV
//
//  Created by Douglass Turner on 3/6/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "NSObject+ClassHierarchyTraversal.h"
#import <objc/runtime.h>

@implementation NSObject (NSObject_ClassHierarchyTraversal)

+ (NSArray *)subClasses {

    Class myClass = [self class];
    NSMutableArray *mySubclasses = [NSMutableArray array];

    unsigned int numOfClasses;
    Class *classes = objc_copyClassList(&numOfClasses);

    for (unsigned int ci = 0; ci < numOfClasses; ci++) {


        // Immediate subclasses only
        Class superClass = class_getSuperclass(classes[ci]);
        if (superClass == myClass) [mySubclasses addObject: classes[ci]];





        // Traversal of deep hierarchy
//        Class superClass = classes[ci];
//        do {
//
//            superClass = class_getSuperclass(superClass);
//
//        } while (superClass && superClass != myClass);
//
//        if (superClass) {
//            [mySubclasses addObject: classes[ci]];
//        }

    } // for (numOfClasses)

    free(classes);

    return mySubclasses;
}

@end
