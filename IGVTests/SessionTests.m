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

@interface SessionTests : SenTestCase
@end


@implementation SessionTests

- (void) testSession {

    NSString *urlString = @"http://www.broadinstitute.org/igvdata/ipad/unittests/tcgascape_session.xml";

    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    STAssertNotNil(data, nil);

    NSError *outError =  NULL;

    // Create the document
    SMXMLDocument *document = [SMXMLDocument documentWithData: data error:  &outError] ;

    if (document == nil && outError != NULL) {
        ALog(@"Error: %@", outError.description)
    }
    STAssertNotNil(document, @"Document nil test");


    LMSession *session = [LMSession sessionWithDocument:document];

    STAssertEqualObjects(session.genome, @"hg19", @"Genome");
    STAssertEqualObjects(session.locus, @"chr16:47645989-48114400", @"Locus");

    NSArray *resources = session.resources;

    STAssertEquals(resources.count, (NSUInteger) 2, @"Resources count");

    LMResource *resource1 = [resources objectAtIndex:0];
    STAssertEqualObjects(resource1.path, @"http://www.broadinstitute.org/igvdata/tcga/tcgascape/120620_pipeline21/breast_invasive_adenocarcinoma.seg.gz", @"path");

    LMResource *resource2 = [resources objectAtIndex:1];
    STAssertEqualObjects(resource2.path, @"http://www.broadinstitute.org/igvdata/tcga/tcgascape/120620_pipeline21/sample_info.txt", @"path");

}



@end