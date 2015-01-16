//
// Created by jrobinso on 7/25/12.
//
// To change the template use AppCode | Preferences | File Templates.
//



#import <SenTestingKit/SenTestingKit.h>
#import "Logging.h"
#import "URLDataLoader.h"
#import "SMXMLDocument.h"
#import "HttpResponse.h"
#import "LMTree.h"
#import "LMCategory.h"
#import "LMResource.h"
#import "LMSession.h"

@interface XMLTests : SenTestCase
@end


@implementation XMLTests

- (void)testDetectionOfEmptyLeaves {

    NSString *urlString = @"http://www.broadinstitute.org/igvdata/annotations/hg18/hg18_annotations.xml";
//    NSString *path = @"http://gdac.broadinstitute.org/tap/igv/load/tcga_hg19.xml";

    HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:urlString];
    STAssertNotNil(response, nil);

    SMXMLDocument *document = [SMXMLDocument documentWithData:response.receivedData error:nil];
    STAssertNotNil(document, nil);

   // ALog(@"%@", document);

//    if ([[document description] rangeOfString:@".xml"].location != NSNotFound) {
//        ALog(@"%@", document);
//    }
}

/*
<Global trackLine="viewLimits=0:25" name="ENCODE (hg18)" version="1">
<Category trackLine="viewLimits=0:25" name="Broad Histone">
<Resource trackLine="viewLimits=0:25" name="GM12878 Input" path="http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalGm12878Control.tdf"/>
<Resource trackLine="viewLimits=0:25" name="GM12878 CTCF" path="http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalGm12878Ctcf.tdf"/>

 */

- (void)testCategoryAndResourcePackagingForResourceTreeController {

//    NSString *path = @"http://www.broadinstitute.org/igvdata/annotations/hg18/hg18_annotations.xml";
//    NSString *path = @"http://www.broadinstitute.org/igvdata/encode/hg18/hg18_encode_color.xml";
//    LMTree *tree = [LMTree treeWithURL:path error:NULL];

    NSArray *xmlFiles = [NSArray arrayWithObjects:
            @"http://www.broadinstitute.org/igvdata/annotations/hg18/hg18_annotations.xml",
            @"http://www.broadinstitute.org/igvdata/encode/hg18/hg18_encode_color.xml",
            nil];

    LMTree *tree = [LMTree treeWithPath:[xmlFiles objectAtIndex:0] error:NULL];


    STAssertNotNil(tree, @"") ;

    LMCategory *rootCategory = tree.rootCategory;
    STAssertNotNil(rootCategory, @"") ;

 //   ALog(@"%@ %@", rootCategory, [rootCategory resourceTreeControllerItems]);


//    NSArray *childCategories = rootCategory.childCategories;
//    STAssertEquals(childCategories.count,  (NSUInteger) 2, @"Child category size");
//
//    LMCategory *child1 = [childCategories objectAtIndex:0];
//    STAssertEqualObjects(child1.name, @"Broad Histone", @"Child 1 name");
//
//    LMCategory *child2= [childCategories objectAtIndex:1];
//    STAssertEqualObjects(child2.name, @"Chromatin States (Broad HMM)", @"Child 2 name");
//
//    NSArray *child1Resources = child1.resources;
//    STAssertEquals(child1Resources.count, (NSUInteger) 93, @"Child 1 resource count");
//
//    LMResource *firstResource = [child1.resources objectAtIndex:0];
//
//    STAssertEqualObjects(firstResource.name, @"GM12878 Input", @"First resource name");
//    STAssertEqualObjects(firstResource.path, @"http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalGm12878Control.tdf", @"First resource path");

}

- (void)testEncodeTree {

    NSString *urlString = @"http://www.broadinstitute.org/igvdata/encode/hg18/hg18_encode_color.xml";

    LMTree *tree = [LMTree treeWithPath:urlString error:NULL];

    STAssertNotNil(tree, @"") ;

    LMCategory *rootCategory = tree.rootCategory;

    STAssertEqualObjects(rootCategory.name, @"ENCODE (hg18)", @"Root category name");

    NSArray *childCategories = rootCategory.childCategories;
    STAssertEquals(childCategories.count,  (NSUInteger) 2, @"Child category size");

    LMCategory *child1 = [childCategories objectAtIndex:0];
    STAssertEqualObjects(child1.name, @"Broad Histone", @"Child 1 name");

    LMCategory *child2= [childCategories objectAtIndex:1];
    STAssertEqualObjects(child2.name, @"Chromatin States (Broad HMM)", @"Child 2 name");

    NSArray *child1Resources = child1.resources;
    STAssertEquals(child1Resources.count, (NSUInteger) 93, @"Child 1 resource count");

    LMResource *firstResource = [child1.resources objectAtIndex:0];

    STAssertEqualObjects(firstResource.name, @"GM12878 Input", @"First resource name");
    STAssertEqualObjects(firstResource.filePath, @"http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalGm12878Control.tdf", @"First resource path");

}


- (void)testParseXML {

    // Step 1 -- get the bits
    NSString *urlString = @"http://www.broadinstitute.org/igvdata/encode/hg18/hg18_encode_color.xml";

    HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:urlString];

    NSData *data = response.receivedData;

    // Create the document
    NSError *error =  nil;
    SMXMLDocument *document = [SMXMLDocument documentWithData:data error:&error] ;

    if (document == nil && error != NULL) {
        ALog(@"Error: %@", error.description)
    }
    STAssertNotNil(document, @"Document nil test");

    SMXMLElement *root = document.root;

    NSString *rootName = root.name;

    STAssertEqualObjects(rootName, @"Global", @"root.name");

//    ALog(@"%@", document);

}

@end