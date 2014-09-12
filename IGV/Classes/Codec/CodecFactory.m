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
//  Created by turner on 2/6/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "CodecFactory.h"
#import "RuntimeUtils.h"
#import "Codec.h"
#import "Logging.h"

@interface CodecFactory ()
@property(nonatomic, retain) NSMutableDictionary *codecClassNames;
@end

@implementation CodecFactory

@synthesize codecClassNames;

- (void)dealloc {

    self.codecClassNames = nil;
    [super dealloc];
}

+(CodecFactory *)sharedCodecFactory {
    
    static dispatch_once_t pred;
    static CodecFactory *shared = nil;
    
    dispatch_once(&pred, ^{
        
        shared = [[CodecFactory alloc] init];
    });
    
    return shared;
    
}

-(NSMutableDictionary *)codecClassNames {

    if (nil == codecClassNames) {

        NSArray *codecClassStrings = [RuntimeUtils classStringsForClassesOfType:[Codec class]];

        self.codecClassNames = [NSMutableDictionary dictionary];

        for (id codecClassString in codecClassStrings) {

            Class codecClass = NSClassFromString(codecClassString);

            if (nil == [codecClass fileSuffixKey]) continue;

            [self.codecClassNames setObject:codecClassString forKey:[codecClass fileSuffixKey]];
        }
    }

    return codecClassNames;
}

- (NSString *)codecClassStringForPath:(NSString *)path {

    NSString *string = ([[path pathExtension] isEqualToString:@"gz"]) ? [path stringByReplacingOccurrencesOfString:@".gz" withString:@""] : path;

    NSString *key = [[string pathExtension] lowercaseString];

    // Handle narrow and broad peak
    key = [key stringByReplacingOccurrencesOfString:@"broadpeak" withString:@"peak"];
    key = [key stringByReplacingOccurrencesOfString:@"narrowpeak" withString:@"peak"];

    NSString *codecClassString = [self.codecClassNames objectForKey:key];

    return codecClassString;
}

- (Codec *)codecForPath:(NSString *)path {

    NSString *codecClassString = [self codecClassStringForPath:path];

    return  [[[NSClassFromString(codecClassString) alloc] init] autorelease];
}

@end
