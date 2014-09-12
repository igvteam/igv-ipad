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
//  BAMRecord.m
//  samtools
//
//  Wraps a "samtools" bam structure
//
//  Created by James Robinson on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.


/*  SAM flags
 private static final int READ_PAIRED_FLAG = 0x1;
 private static final int PROPER_PAIR_FLAG = 0x2;
 private static final int READ_UNMAPPED_FLAG = 0x4;
 private static final int MATE_UNMAPPED_FLAG = 0x8;
 private static final int READ_STRAND_FLAG = 0x10;
 private static final int MATE_STRAND_FLAG = 0x20;
 private static final int FIRST_OF_PAIR_FLAG = 0x40;
 private static final int SECOND_OF_PAIR_FLAG = 0x80;
 private static final int NOT_PRIMARY_ALIGNMENT_FLAG = 0x100;
 private static final int READ_FAILS_VENDOR_QUALITY_CHECK_FLAG = 0x200;
 private static final int DUPLICATE_READ_FLAG = 0x400;
 */#import "AlignmentBlockItem.h"

#import "AlignmentBlock.h"
#import "Alignment.h"
#import "Logging.h"
#import "IGVHelpful.h"
#import "AlignmentBlockItem.h"

//#define TMAX(a, b) ((a) > (b) ? (a) : (b))
//#define TMIN(a, b) ((a) < (b) ? (a) : (b))

@interface Alignment ()
@property(nonatomic, retain) NSString *queryName;
@end

@implementation Alignment {

@private
    uint8_t *_qualities;
    char *_bases;
}

static const char cigarOperators[9] = {'M', 'I', 'D', 'N', 'S', 'H', 'P', '=', 'X'};
//static  int READ_PAIRED_FLAG = 0x1;
//static  int PROPER_PAIR_FLAG = 0x2;
static  int READ_UNMAPPED_FLAG = 0x4;
//static  int MATE_UNMAPPED_FLAG = 0x8;
static  int READ_STRAND_FLAG = 0x10;
//static  int MATE_STRAND_FLAG = 0x20;
//static  int FIRST_OF_PAIR_FLAG = 0x40;
//static  int SECOND_OF_PAIR_FLAG = 0x80;
//static  int NOT_PRIMARY_ALIGNMENT_FLAG = 0x100;
//static  int READ_FAILS_VENDOR_QUALITY_CHECK_FLAG = 0x200;
//static  int DUPLICATE_READ_FLAG = 0x400;

@synthesize start;
@synthesize end;
@synthesize negativeStrand;
@synthesize queryName;
@synthesize unmapped;
@synthesize alignmentBlocks = _alignmentBlocks;
@synthesize cigar;
@synthesize quality = _quality;
@synthesize gapLineStyle = _gapLineStyle;

- (void) dealloc {

    self.queryName = nil;
    self.alignmentBlocks = nil;
    self.cigar = nil;

    free(_qualities);
    free(_bases);

    [super dealloc];
}

- (id) initWithStructure: (const bam1_t *) b {

    self = [super init];
    
    if(self) {

        const bam1_core_t core = b->core;

        self.quality = (uint8_t)core.qual;

        uint32_t* _cigar =((uint32_t*)((b)->data + (b)->core.l_qname));
        
        self.queryName = [[[NSString alloc] initWithUTF8String: ((char *) (b->data))] autorelease];
        
        int l_qseq = b->core.l_qseq;
        
        // We use char arrays here, instead of NSMutableData, so we can do pointer arithmetic to get sequences for the alignmentBlocks
        uint8_t* qualData = (uint8_t *)  bam1_qual(b);
        uint8_t* baseData = (uint8_t *)  bam1_seq(b);
           
        _qualities = calloc((size_t)l_qseq + 1, sizeof(uint8_t));
        _bases     = calloc((size_t)l_qseq + 1, sizeof(char));
       
        BOOL noQualities = qualData[0] == 0xff;
        for (int i = 0; i < l_qseq; ++i) {

            _bases[i] = bam_nt16_rev_table[bam1_seqi(baseData, i)];
            _qualities[i] = noQualities ? (uint8_t)64 : qualData[i];
        }
        _bases[l_qseq] = 0;
        _qualities[l_qseq]  = 0;

        self.start = b->core.pos;// + 2;        // +1 ?
        self.end = bam_calend(&(b->core), _cigar);// + 2;      // +1?

        self.negativeStrand = (BOOL)(core.flag&READ_STRAND_FLAG);
        
        self.unmapped = (BOOL)(core.flag&READ_UNMAPPED_FLAG);
        
        int n_cigar = core.n_cigar;
        self.cigar = [NSMutableString stringWithCapacity:(NSUInteger)(3 * n_cigar)];

        // gap line style defaults to 'D' for deletion
        self.gapLineStyle = 'D';

        short readOffset = 0;
        long long int blockStart = self.start;

        for(int i=0; i < n_cigar; i++) {

            short opLength = (short) (_cigar[i]>>4);

            int op = (int) (_cigar[i]&0xf);

            [self.cigar appendFormat: @"%d%c", opLength, cigarOperators[op]];
            
            char cigarOp = cigarOperators[op];

            switch(cigarOp) {
                case 'H':
                    break;
                case 'P':
                    break;
                case 'S':
                    readOffset += opLength;
                    break;
                case 'N':
                {
                    self.gapLineStyle = 'N';
                    blockStart += opLength;
                }
                    break;
                case 'D' :
                    blockStart += opLength;
                    break;
                case 'I':
                    readOffset += opLength;
                    break;
                case 'M':
                case '=':
                case 'X': {
                    
                    AlignmentBlock *alignmentBlock = [[AlignmentBlock alloc] initWithAlignment:self start:blockStart readBase:readOffset length:opLength];
                    [self.alignmentBlocks addObject:alignmentBlock];
                    [alignmentBlock release];
                    
                    readOffset += opLength;
                    blockStart += opLength;

                    break;
                }

                default:
                    ALog(@"Huh?");
                    
            }  
        }
    }
    
    // Note - the bam structure (b) is destroyed by the bam_fetch function.
    
    return self;
}

- (NSMutableArray *)alignmentBlocks {

    if (nil == _alignmentBlocks) {
        self.alignmentBlocks = [NSMutableArray array];
    }

    return _alignmentBlocks;
}

- (char *) bases {
    return _bases;
}

- (u_int8_t *) qualities {
    return _qualities;
}

- (long long int)length {
//    return (self.end - self.start) + 1;
    return self.end - self.start;
}

-(AlignmentBlockItem *)alignmentBlockItemAtLocation:(long long int)location {

    if (location < self.start || location > self.end) {
        return nil;
    }

    for (AlignmentBlock *alignmentBlock in self.alignmentBlocks) {

        long long int alignmentBlockBasesListIndex = location - alignmentBlock.start;

        if (alignmentBlockBasesListIndex < 0 || alignmentBlockBasesListIndex >= alignmentBlock.length ) {
            continue;
        }

        AlignmentBlockItem *alignmentBlockItem = [[[AlignmentBlockItem alloc] initWithBase:alignmentBlock.bases[alignmentBlockBasesListIndex]
                                                                                   quality:alignmentBlock.qualities[alignmentBlockBasesListIndex]] autorelease];

        return alignmentBlockItem;
    }

    return nil;

}

-(BOOL)bboxHitTest:(long long int)value {
    return (value < self.start || value > self.end) ? NO : YES;
}

+ (float) alphaFromQuality:(u_int8_t)quality {
	
	float alpha;

	float q = (float)quality;
	
	if (q < 5) {		
		alpha = 0.1;
	} else if(q > 20) {
        alpha = 1;
    } else{
        alpha = MAX(0.1, MIN(1.0, 0.1 + 0.9 * (q - 5) / (20 - 5)));
    }
    return alpha;
}

// units: points
+ (double)mismatchSearchWindow {
    return 36;
}

- (NSString *)description {

    NSString *ss  = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:start]];
    NSString *ee  = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:  end]];

    NSString *blockOffsets = @"";
    for (AlignmentBlock *alignmentBlock in self.alignmentBlocks) {
        blockOffsets = [blockOffsets stringByAppendingString:[NSString stringWithFormat:@"[offset %lld length %d] ", alignmentBlock.start - self.start, alignmentBlock.length]];
    }
    return [NSString stringWithFormat:@"%@ start %@ end %@ length %lld blocks %@", [self class], ss, ee, [self length], blockOffsets];
}

@end

