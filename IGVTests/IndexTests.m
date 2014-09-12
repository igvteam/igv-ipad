//
// Created by jrobinso on 7/27/12.
//
// To change the template use AppCode | Preferences | File Templates.
//



#import <SenTestingKit/SenTestingKit.h>
#import "LinearIndex.h"
#import "IndexFactory.h"
#import "Logging.h"
#import "ChrIndex.h"
#import "FileRange.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"

@interface IndexTests : SenTestCase
@end

@implementation IndexTests

- (void) testIndex {

    NSString *path = @"http://dl.dropboxusercontent.com/u/11270323/BroadInstitute/BED/exon_utr_render_test.bed";

    NSError *error = NULL;
    LinearIndex *linearIndex = [IndexFactory indexFromFile:[NSString stringWithFormat:@"%@.idx", path] withError:&error];
    STAssertNotNil(linearIndex, nil);

    NSMutableDictionary *chrDict = linearIndex.chrIndices;

//    for (NSString *key in chrDict.allKeys) {
//        ALog(@"%@", key);
//        ChrIndex *chrIndex = [chrDict objectForKey:key];
//
//        NSArray *blocks = chrIndex.blocks;
//        for (FileRange *block in blocks) {
//            ALog(@"%d", block.position);
//            ALog(@"%d", block.byteCount);
//        }
//    }

    // locus
    NSString *chr = @"chr1";
    int start = 1197974;
    int end   = 1291459;

    ChrIndex *chrIndex = [linearIndex.chrIndices objectForKey:chr];
    FileRange *entry = [chrIndex getRangeOverlapping:start end:end];

    FileRange *range = [FileRange rangeWithPosition:entry.position byteCount:entry.byteCount];
    HttpResponse *httpResponse = [URLDataLoader loadDataSynchronousWithPath:path forRange:range];
    STAssertNotNil(httpResponse, nil);

    NSString *str = [[[NSString alloc] initWithBytes:httpResponse.receivedData.bytes length:httpResponse.receivedData.length encoding:NSUTF8StringEncoding] autorelease];

    ALog( @"%@", str);
}
@end