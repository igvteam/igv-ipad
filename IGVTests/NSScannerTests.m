//
// Created by turner on 7/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <SenTestingKit/SenTestingKit.h>
#import "Logging.h"
#import "IGVAppDelegate.h"

@interface NSScannerTests : SenTestCase
@end

@implementation NSScannerTests

- (void)testPortalURLLoading {

    NSScanner *scanner = [NSScanner scannerWithString:@"igvipadapp://eval?file=https://something.bar&locus=chr18:4,000,000-4,000,150"];

    NSString *guard = @"://";

    NSString *discard;
    [scanner scanUpToString:guard intoString:&discard];

    // discard guard
    [scanner scanString:guard intoString:NULL];

    // scan remainder and keep it
    NSString *keeper;
    [scanner scanUpToString:@"" intoString:&keeper];

    NSArray *parts = [keeper componentsSeparatedByString:@"?"];

    NSMutableDictionary *commandDictionary = [NSMutableDictionary dictionary];
    if (2 == [parts count]) {

        NSArray *commands = [[parts objectAtIndex:1] componentsSeparatedByString:@"&"];
        for (NSString *command in commands) {

            NSArray *key_value = [command componentsSeparatedByString:@"="];
            [commandDictionary setObject:[key_value objectAtIndex:1] forKey:[key_value objectAtIndex:0]];
        }

    }

    NSArray *fileCommands = [[commandDictionary objectForKey:kCommandResourceKey] componentsSeparatedByString:@","];
    ALog(@"%@", [fileCommands objectAtIndex:0]);

}

- (void)testNSScannerUsage {

    NSScanner *scanner = [NSScanner scannerWithString:@"0,4738,6719,10348,13067,18576,19099,20865,22610,23907,27470,27883,"];

    while (![scanner isAtEnd]) {

        NSString *string;
        [scanner scanUpToString:@"," intoString:&string];
        [scanner scanString:@"," intoString:NULL];
        ALog(@"%@", string);
    }
}

@end