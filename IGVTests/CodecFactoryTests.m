//
// Created by turner on 5/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <SenTestingKit/SenTestingKit.h>
#import "CodecFactory.h"
#import "Logging.h"
#import "Codec.h"

@interface CodecFactoryTests : SenTestCase
@end

@implementation CodecFactoryTests

- (void)testCodecFactory {

    NSArray *urlStrings = [NSArray arrayWithObjects:

            @"http:////www.broadinstitute.org/software/igv/sites/cancerinformatics.org.igv/files/linked_files/example.seg",

            @"http://dl.dropbox.com/u/11270323/BroadInstitute/BEDFiles/hg18_refseq_genes.bed",
            @"http://dl.dropbox.com/u/11270323/BroadInstitute/BEDFiles/exonRenderingBug.bed",
            @"http://dl.dropbox.com/u/11270323/BroadInstitute/BEDFiles/snp_8000.bed",

            @"http://dl.dropbox.com/u/11270323/BroadInstitute/BEDFiles/snpSamples.bed.gz",
            @"http://dl.dropbox.com/u/11270323/BroadInstitute/BEDFiles/snp_128.bed.gz",
            @"http://dl.dropbox.com/u/11270323/BroadInstitute/BEDFiles/snp_8000.bed.gz",

            @"http://dl.dropbox.com/u/11270323/BroadInstitute/WIGFiles/hg18_egfr_cons.wig",
            @"http://dl.dropbox.com/u/11270323/BroadInstitute/WIGFiles/hg18_egfr_cons.wig.gz",


            nil];

    for (NSString *urlString in urlStrings) {

        Codec *codec = [[CodecFactory sharedCodecFactory] codecForPath:urlString];
        STAssertNotNil(codec, nil);
    }

}

@end
