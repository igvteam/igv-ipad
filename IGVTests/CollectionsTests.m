//
// Created by jrobinso on 7/27/12.
//
// To change the template use AppCode | Preferences | File Templates.
//



#import <SenTestingKit/SenTestingKit.h>
#import "FloatArray.h"
#import "IntArray.h"



@interface CollectionsTests : SenTestCase
@end
@implementation CollectionsTests {

}


- (void) testFloatArray {

    FloatArray *floatArray = [FloatArray arrayWithCapacity: 10];

    // Add enought numbers to grow the array twice
    int n = 25;
    for (int i = 0; i < n; i++) {
        [floatArray addFloat: (float) i];
    }

    STAssertEquals(floatArray.count, n, @"Count") ;

    for (int i = 0; i < n; i++) {
        STAssertEquals([floatArray floatAtIndex:i], (float) i, @"Value");
    }
}


- (void) testIntArray {

    IntArray *intArray = [IntArray arrayWithCapacity: 10];

    // Add enought numbers to grow the array twice
    int n = 25;
    for (int i = 0; i < n; i++) {
        [intArray addInt:  i];
    }

    STAssertEquals(intArray.count, n, @"Count") ;

    for (int i = 0; i < n; i++) {
        STAssertEquals([intArray intAtIndex:i],  i, @"Value");
    }
}


@end