//
//  MIT License
//
//  Copyright (c) 2011 Bob McCune http://bobmccune.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "RuntimeUtils.h"
#import <objc/runtime.h>

@implementation RuntimeUtils

+ (NSArray *)classStringsForClassesAdoptingProtocol:(Protocol *)protocol {
	
	int numClasses = 0, newNumClasses = objc_getClassList(NULL, 0);
	Class *classes = NULL;
	
	while (numClasses < newNumClasses) {
        numClasses = newNumClasses;
        classes = realloc(classes, sizeof(Class) * numClasses);
        newNumClasses = objc_getClassList(classes, numClasses);
    }
	
	NSMutableArray *classesArray = [NSMutableArray array];
	
	for (int i = 0; i < numClasses; i++) {
		// if class conforms to desired protocol, add it to the array
		if (class_conformsToProtocol(classes[i], protocol)) {
			[classesArray addObject:NSStringFromClass(classes[i])];			
		}
	}
	
    free(classes);
	
	return classesArray;
}

+ (NSArray *)classStringsForClassesOfType:(Class)filterType {
	
	int numClasses = 0, newNumClasses = objc_getClassList(NULL, 0);
	Class *classList = NULL;
	
	while (numClasses < newNumClasses) {
        numClasses = newNumClasses;
        classList = realloc(classList, sizeof(Class) * numClasses);
        newNumClasses = objc_getClassList(classList, numClasses);
    }
	
	NSMutableArray *classesArray = [NSMutableArray array];

	for (int i = 0; i < numClasses; i++) {
		Class superClass = classList[i];
		do {
			// recursively walk the inheritance hierarchy
			superClass = class_getSuperclass(superClass);
			if (superClass == filterType) {
				[classesArray addObject:NSStringFromClass(classList[i])];
				break;
			}			
		} while (superClass);		
	}

    free(classList);
	
	return classesArray;
}

@end
