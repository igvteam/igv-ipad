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
//  IGVApplication.m
//  IGV
//
//  Created by Douglass Turner on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ZoomSlider.h"
#import "UINavigationItem+RootContentController.h"
#import "RootContentController.h"
#import <sys/sysctl.h>
#import "IGVAppDelegate.h"
#import "Reachability.h"
#import "IGVContext.h"
#import "Logging.h"
#import "NSUserDefaults+LocusFileURL.h"
#import "LocusListItem.h"
#import "LMResource.h"
#import "GenomeManager.h"
#import "CytobandTrackView.h"
#import "FileURLDialogController.h"
#import "TrackController.h"
#import "NetworkStatusController.h"
#import "IGVHelpful.h"
#import "UIApplication+IGVApplication.h"
#import "NSMutableDictionary+TrackController.h"
#import "GeneNameServiceController.h"
#import "LMSession.h"
#import "PListPersistence.h"
#import "AlignmentTrackView.h"

static const long long int kLocusHalfWidth = 40;
//static const long long int kLocusHalfWidth = 24;

@interface IGVAppDelegate ()
- (void)launchApplicationViaURLWithNotification:(NSNotification *)notification;
- (void)launchApplicationWithCommandDictionary;
- (LocusListItem *)locusListItemWithLocus:(NSString *)locus;
+ (NSArray *)resourcesWithPaths:(NSArray *)paths;
+ (NSMutableDictionary *)commandsWithURLString:(NSString *)urlString;
+ (NSArray *)getLocusCommand:(NSString *)string;
+ (BOOL)isXMLSessionFile:(NSString *)string;

+ (BOOL)isValidCommandDictionary:(NSDictionary *)commandDictionary;

+ (void)getDeviceCharacteristics;
@end

@implementation IGVAppDelegate

@synthesize window;
@synthesize bamDataRetrievalQueue = _bamDataRetrievalQueue;
@synthesize trackControllerQueue = _trackControllerQueue;
@synthesize featureSourceQueue = _featureSourceQueue;
@synthesize commandDictionary = _commandDictionary;

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:DidLaunchApplicationViaURLNotification object:nil];

    dispatch_release(_bamDataRetrievalQueue);
    dispatch_release(_trackControllerQueue);
    dispatch_release(_featureSourceQueue);

    self.navigationController = nil;
    self.window = nil;
    self.commandDictionary = nil;

    [super dealloc];
}

-(id)init {

    self = [super init];
    if (nil != self) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchApplicationViaURLWithNotification:) name:DidLaunchApplicationViaURLNotification object:nil];
    }

    return self;
}

- (dispatch_queue_t)bamDataRetrievalQueue {

    if (nil == _bamDataRetrievalQueue) {

        NSString *queueName = [NSString stringWithFormat:@"org.broadinstitute.igv.%@", [AlignmentTrackView class]];
        self.bamDataRetrievalQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }

    return _bamDataRetrievalQueue;
}

- (dispatch_queue_t)trackControllerQueue {

    if (nil == _trackControllerQueue) {

        NSString *queueName = [NSString stringWithFormat:@"org.broadinstitute.igv.%@", [TrackController class]];
        self.trackControllerQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }

    return _trackControllerQueue;
}

- (dispatch_queue_t)featureSourceQueue {

    if (nil == _featureSourceQueue) {

        NSString *queueName = [NSString stringWithFormat:@"org.broadinstitute.igv.%@", [BaseFeatureSource class]];
        self.featureSourceQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }

    return _featureSourceQueue;
}

- (void)disableUserInteraction {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    ZoomSlider *zoomSlider = [rootContentController.navigationItem zoomSlider];
    zoomSlider.enabled = NO;
    zoomSlider.userInteractionEnabled = NO;

    UITextField *textField = [rootContentController.navigationItem gotoTextField];
    textField.enabled = NO;
    textField.userInteractionEnabled = NO;

    UISegmentedControl *segmentedControl = [rootContentController.navigationItem genomesTracksLociSegmentedControl];
    segmentedControl.enabled = NO;
    segmentedControl.userInteractionEnabled = NO;

    rootContentController.view.userInteractionEnabled = NO;

    rootContentController.rootScrollView.scrollEnabled = NO;

    rootContentController.allowOrientationChange = NO;

    [rootContentController spinnerSpin:YES];

}

- (void)enableUserInteraction {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    [rootContentController spinnerSpin:NO];

    rootContentController.allowOrientationChange = YES;

    rootContentController.rootScrollView.scrollEnabled = YES;

    rootContentController.view.userInteractionEnabled = YES;

    UISegmentedControl *segmentedControl = [rootContentController.navigationItem genomesTracksLociSegmentedControl];
    segmentedControl.enabled = YES;
    segmentedControl.userInteractionEnabled = YES;

    UITextField *textField = [rootContentController.navigationItem gotoTextField];
    textField.enabled = YES;
    textField.userInteractionEnabled = YES;

    ZoomSlider *zoomSlider = [rootContentController.navigationItem zoomSlider];
    zoomSlider.enabled = YES;
    zoomSlider.userInteractionEnabled = YES;

}

#pragma mark - UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    if (nil != launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
        NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        self.commandDictionary = [IGVAppDelegate commandsWithURLString:[launchURL absoluteString]];
    }

    [[NSUserDefaults standardUserDefaults] registerDefaultsFromSettingsBundle];

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor grayColor];

//    ///////////////////////////////////////////////////
//    self.window.layer.contents = (id) [UIImage imageNamed:@"graph-paper"].CGImage;
//    ///////////////////////////////////////////////////

    self.navigationController = [[[UINavigationController alloc] initWithNibName:@"RootContainerController" bundle:nil] autorelease];
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];

    self.window.rootViewController = self.navigationController;

    NetworkStatusController *networkDownController = [[[NetworkStatusController alloc] initWithNibName:@"NetworkStatusController" bundle:nil] autorelease];
    [self.navigationController pushViewController:networkDownController animated:NO];

    if ([IGVHelpful networkStatus]) {
        [self presentRootContentController];
    } else {

        UIView *child = [networkDownController.view.subviews objectAtIndex:0];
        child.hidden = NO;
    }

    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    if (nil == self.commandDictionary) {

        // application was foreground'ed from background
        self.commandDictionary = [IGVAppDelegate commandsWithURLString:[url absoluteString]];

        [[NSNotificationCenter defaultCenter] postNotificationName:DidLaunchApplicationViaURLNotification object:nil];


    } else {

        // application was launched from scratch. Notification DidLaunchApplicationViaURLNotification will be sent
        // from RootController method trackDidFinishRenderingWithNotification:
    }

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

    self.commandDictionary = nil;

    if (nil == [IGVContext sharedIGVContext].chromosomeName) {
        return;
    }

    NSString *launchLocus = [[IGVContext sharedIGVContext] currentLocus];
    LocusListFormat locusListFormat = [launchLocus format];
    LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:launchLocus
                                                                   label:@"LaunchWithLocus"
                                                         locusListFormat:locusListFormat
                                                              genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

    [[NSUserDefaults standardUserDefaults] setAppLaunchLocusWithLocusListItem:locusListItem forKey:kLocusAtAppLaunch];

}

#pragma mark - IGVAppDelegate Methods

- (void)launchApplicationViaURLWithNotification:(NSNotification *)notification {

    if (nil == self.commandDictionary) {
        return;
    }

    if (![IGVAppDelegate isValidCommandDictionary:self.commandDictionary]) {

        return;
    }

    [self launchApplicationWithCommandDictionary];
}

- (void)launchApplicationWithCommandDictionary {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    NSMutableArray *commands = [NSMutableArray array];
    if ([self.commandDictionary objectForKey:@"genome"]) [commands addObject:@"genome"];
    if ([self.commandDictionary objectForKey:@"locus"]) [commands addObject:@"locus"];
    if ([self.commandDictionary objectForKey:kCommandResourceKey]) [commands addObject:kCommandResourceKey];

    if (0 == [commands count]) {
        ALog(@"All commands consumed. Done.");
        return;
    }

    for (NSString *command in commands) {

        ALog(@"process %@ of %@", command, commands);

        // genome
        if ([command isEqualToString:@"genome"]) {

            NSString *genome = [NSString stringWithFormat:@"%@", [self.commandDictionary objectForKey:@"genome"]];
            [self.commandDictionary removeObjectForKey:@"genome"];

            if (genome && ![genome isEqualToString:[GenomeManager sharedGenomeManager].currentGenomeName]) {

                [rootContentController.trackControllers removeAllTracks];

                [GenomeManager sharedGenomeManager].currentGenomeName = genome;
                [rootContentController selectGenomeWithGenomeManager:[GenomeManager sharedGenomeManager]
                                                       locusListItem:nil];

            } else {

                [[NSNotificationCenter defaultCenter] postNotificationName:DidLaunchApplicationViaURLNotification object:nil];
            }

            return;
        }

        // locus
        if ([command isEqualToString:@"locus"]) {

            NSString *locus = [NSString stringWithFormat:@"%@", [self.commandDictionary objectForKey:@"locus"]];
            [self.commandDictionary removeObjectForKey:@"locus"];

            LocusListItem *locusListItem = [self locusListItemWithLocus:locus];

            [IGVContext sharedIGVContext].chromosomeName = locusListItem.chromosomeName;
            dispatch_async(dispatch_get_main_queue(), ^{

                [rootContentController.rootScrollView setContentOffsetWithLocusListItem:locusListItem disableUI:YES];
                [rootContentController.trackControllers renderAllTracks];
            });

            return;
        }

        // kCommandResourceKey
        if ([command isEqualToString:kCommandResourceKey]) {

            [rootContentController.trackControllers removeAllTracks];

            NSArray *resources = [NSArray arrayWithArray:[self.commandDictionary objectForKey:kCommandResourceKey]];
            [self.commandDictionary removeObjectForKey:kCommandResourceKey];

            NSNumber *appLaunchLocusCentroid = nil;
            if ([self.commandDictionary objectForKey:@"appLaunchLocusCentroid"]) {
                appLaunchLocusCentroid = [NSNumber numberWithLongLong:[[self.commandDictionary objectForKey:@"appLaunchLocusCentroid"] longLongValue]];
            }

            [rootContentController enableTracksWithResources:resources appLaunchLocusCentroid:appLaunchLocusCentroid];

            return;
        }

    }

}

- (LocusListItem *)locusListItemWithLocus:(NSString *)locus {

    // recognize multiple gene names
    NSArray *genes = [locus componentsSeparatedByString:@"%20"];

    // select first gene name
    NSArray *results = [GeneNameServiceController locusForGene:[genes objectAtIndex:0]];

    if (nil != results) {

        // brca1
//        NSString *geneLocus =  @"chr17:41,196,311-41,277,501";
        NSString *geneLocus = [[results objectAtIndex:0] objectAtIndex:1];

        LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:geneLocus
                                                                       label:@""
                                                             locusListFormat:[geneLocus format]
                                                                  genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

        return locusListItem;
    }

    else if (LocusListFormatChrLocusCentroid == [locus format]) {
        
        NSArray *parts = [locus locusComponentsWithFormat:LocusListFormatChrLocusCentroid];

        // add  appLaunchLocusCentroid as another command to the command dictionary. It will be picked up
        // when we parse the "file" command.
        NSNumber *appLaunchLocusCentroid = [NSNumber numberWithLongLong:[[parts objectAtIndex:1] longLongValue]];
        [self.commandDictionary setObject:appLaunchLocusCentroid forKey:@"appLaunchLocusCentroid"];

        return [LocusListItem locusWithChromosome:[parts objectAtIndex:0] centroid:[[parts objectAtIndex:1] longLongValue] halfWidth:kLocusHalfWidth genomeName:nil];
    }

    else {
        return [[[LocusListItem alloc] initWithLocus:locus label:@"" locusListFormat:[locus format] genomeName:nil] autorelease];
    }
}

+ (NSArray *)resourcesWithPaths:(NSArray *)paths {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    NSMutableSet *currentPathSet = [NSMutableSet setWithArray:[rootContentController.trackControllers allKeys]];

    __block NSMutableArray *resources = [NSMutableArray array];
    [paths enumerateObjectsUsingBlock:^(NSString *path, NSUInteger index, BOOL *stop) {

        if (![currentPathSet containsObject:path]) {

            if ([IGVHelpful isUsablePath:[path removeHeadTailWhitespace] blurb:nil]) {
                [resources addObject:[LMResource resourceWithName:nil filePath:path]];
            }

        } else {
            ALog(@"Ignore %@", path);
        }

    }];

    return resources;

}

- (void)presentRootContentController {

    RootContentController *rootContentController = [[[RootContentController alloc] initWithNibName:@"RootContentController" bundle:nil] autorelease];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        rootContentController.edgesForExtendedLayout = UIRectEdgeNone;
    }

    [self.navigationController pushViewController:rootContentController animated:NO];
}

+ (NSMutableDictionary *)commandsWithURLString:(NSString *)urlString {

    NSString *guard = nil;
    NSScanner *scanner = [NSScanner scannerWithString:urlString];

    guard = @"://";
    [scanner scanUpToString:guard intoString:nil];
    [scanner scanString:guard intoString:nil];

    guard = @"eval?";
    [scanner scanUpToString:guard intoString:nil];
    [scanner scanString:guard intoString:nil];

    NSString *keeper = nil;
    [scanner scanUpToString:@"" intoString:&keeper];

    NSMutableDictionary *commandDictionary = [NSMutableDictionary dictionary];

    // Handle XML files received from TCGA and TumorScape portals
    if ([self isXMLSessionFile:keeper]) {

        NSArray* locusCommand = [self getLocusCommand:keeper];
        if (locusCommand) {
            [commandDictionary setObject:[locusCommand objectAtIndex:1] forKey:[locusCommand objectAtIndex:0]];
        }

        LMSession *session = [LMSession sessionWithPath:[self getXMLSessionServiceFile:keeper]];

        if (session.genome && ![session.genome isEqualToString:[GenomeManager sharedGenomeManager].currentGenomeName]) {
            [commandDictionary setObject:session.genome forKey:@"genome"];
        }

        if (session.locus ) {
            [commandDictionary setObject:session.locus  forKey:@"locus"];
        }

        if (session.resources && [session.resources count] > 1) {

            NSMutableArray *resources = [NSMutableArray array];
            for (LMResource *resource in session.resources) {

                // ignore txt files
                if ([resource.filePath rangeOfString:@".txt"].location != NSNotFound) {
                    continue;
                } else {
                    [resources addObject:resource];
                }
            }

            if ([resources count] > 0) {
                [commandDictionary setObject:resources forKey:kCommandResourceKey];
            }
        }

        return ([[commandDictionary allKeys] count] > 0) ? commandDictionary : nil;
    }

    NSString *command;
    NSArray *key_value;
    NSArray *commands = [keeper componentsSeparatedByString:@"&"];
    for (command in commands) {

        key_value = [command componentsSeparatedByString:@"="];
        if ([[key_value objectAtIndex:0] isEqualToString:kCommandResourceKey]) {

            NSArray *paths = [[key_value objectAtIndex:1] componentsSeparatedByString:@","];

            NSArray *resources = [IGVAppDelegate resourcesWithPaths:paths];
            if (resources && [resources count] > 0) {
                [commandDictionary setObject:[IGVAppDelegate resourcesWithPaths:paths] forKey:[key_value objectAtIndex:0]];
            }

        } else {

            [commandDictionary setObject:[key_value objectAtIndex:1] forKey:[key_value objectAtIndex:0]];
        }

    }

    return commandDictionary;
}

+ (NSString *)getXMLSessionServiceFile:(NSString *)string {

    NSString *guard = nil;
    NSScanner *scanner = nil;
    NSString *keeper = nil;
    NSString *path = nil;

    guard = @"file=";
    scanner = [NSScanner scannerWithString:string];
    [scanner scanUpToString:guard intoString:nil];
    [scanner scanString:guard intoString:nil];
    [scanner scanUpToString:@"" intoString:&keeper];

    guard = @"&locus=";
    scanner = [NSScanner scannerWithString:keeper];
    [scanner scanUpToString:guard intoString:&path];

    return path;
}

+ (NSArray *)getLocusCommand:(NSString *)string {

    NSArray *pieces = [string componentsSeparatedByString:@"&"];

    for (NSString *piece in pieces) {

        if ([piece rangeOfString:@"locus="].location != NSNotFound) {
            return [piece componentsSeparatedByString:@"="];
        }
    }

    return nil;
}

+ (BOOL)isXMLSessionFile:(NSString *)string {
    return ([string rangeOfString:@".xml"].location != NSNotFound);
}

+ (BOOL)isValidCommandDictionary:(NSDictionary *)commandDictionary {

    // file paths are handled in [IGVAppDelegate resourcesWithPaths:paths]


    if ([commandDictionary objectForKey:@"genome"] && ![GenomeManager isValideGenomeName:[commandDictionary objectForKey:@"genome"]]) {
        return NO;
    }

    if ([commandDictionary objectForKey:@"locus"]) {

        NSString *locus = [commandDictionary objectForKey:@"locus"];
        if (LocusListFormatInvalid == [locus format]) {
            return NO;
        }
    }

    if ([commandDictionary objectForKey:@"appLaunchLocusCentroid"]) {

        NSString *locus = [commandDictionary objectForKey:@"appLaunchLocusCentroid"];
        if (LocusListFormatInvalid == [locus format]) {
            return NO;
        }
    }

    return YES;
}

+ (BOOL)isValidPath:(NSString *)path {
    return NO;
}

+ (void)getDeviceCharacteristics {

    return;

    ALog(@"device            name %@", [[UIDevice currentDevice] name]);
    ALog(@"device              OS %@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]);

//    UIDeviceHardware *hardware = [[[UIDeviceHardware alloc] init] autorelease];
//    ALog(@"device        hardware %@", [hardware platformString]);

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);

    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);

    ALog(@"device        platform %@", platform);

}

@end
