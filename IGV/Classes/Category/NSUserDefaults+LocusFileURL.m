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
//  Created by turner on 3/1/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NSUserDefaults+LocusFileURL.h"
#import "FileListItem.h"
#import "LocusListItem.h"
#import "Logging.h"

NSString *const kFilesListDefaults = @"fileList";
NSString *const kLocusListDefaults = @"LocusListDefaults";
NSString *const kLocusAtAppLaunch  = @"LocusAtAppLaunch";

NSString *const kAlignmentWindowSizeKey  = @"windowSizeKey";
NSString *const kAlignmentWindowDepthKey  = @"windowDepthKey";
NSString *const kAlignmentVisibilityThresholdKey  = @"alignmentVisibilityThresholdKey";

@implementation NSUserDefaults (IGV_Persistance)

- (void)setAppLaunchLocusWithLocusListItem:(LocusListItem *)locusListItem forKey:(NSString *)key {

    NSDictionary *appLaunchLocusItem = [locusListItem locusListDefaultsItem];

    [self setObject:appLaunchLocusItem forKey:key];

    BOOL success = [[NSUserDefaults standardUserDefaults] synchronize];
    if (!success) {
        DLog(@"Syncronization of user defaults failed");
    }

}

- (void)addFileListItem:(FileListItem *)fileListItem forKey:(NSString *)key {

    NSMutableArray *fileListDefaults = [NSMutableArray arrayWithArray:[self arrayForKey:key]];

    if ([self isDuplicateFileListItem:fileListItem forKey:key ]) {
        return;
    }

    // prepend item
    NSDictionary *item = [fileListItem fileListDefaultsItem];
    [fileListDefaults insertObject:item atIndex:0];

    [self setObject:fileListDefaults forKey:key];

    BOOL success = [self synchronize];
    if (!success) {
        ALog(@"Syncronization failed");
    }

}

- (void)removeFileListItem:(FileListItem *)fileListItem forKey:(NSString *)key {

    NSMutableArray *fileListDefaults = [NSMutableArray arrayWithArray:[self arrayForKey:key]];

    if (nil == fileListDefaults) {
        return;
    }

    NSDictionary *item = [fileListItem fileListDefaultsItem];
    NSDictionary *candidate = nil;
    for (NSDictionary *fileListDefault in fileListDefaults) {

        NSString *k = [[item allKeys] objectAtIndex:0];

        if (nil != [fileListDefault objectForKey:k]) {
            candidate = fileListDefault;
            break;
        }
    }

    if (nil == candidate) {
        return;
    }

    [fileListDefaults removeObject:candidate];
    [self setObject:fileListDefaults forKey:key];

    BOOL success = [self synchronize];
    if (!success) {
        ALog(@"Syncronization failed");
    }


}

- (BOOL)isDuplicateFileListItem:(FileListItem *)fileListItem forKey:(NSString *)key {

    NSMutableArray *fileListDefaults = [NSMutableArray arrayWithArray:[self arrayForKey:key]];

    for (NSDictionary *fileListDefault in fileListDefaults) {

        NSString *keyA = [[fileListDefault allKeys] objectAtIndex:0];
        NSString *keyB = [[[fileListItem fileListDefaultsItem] allKeys] objectAtIndex:0];

        if ([keyA isEqualToString:keyB]) {
            return YES;
        }
    }

    return NO;
}

- (void)addLocusListItem:(LocusListItem *)locusListItem forKey:(NSString *)key {

    NSMutableArray *locusListDefaults = [NSMutableArray arrayWithArray:[self arrayForKey:key]];

    NSDictionary *item = [locusListItem locusListDefaultsItem];
    [locusListDefaults insertObject:item atIndex:0];

    [self setObject:locusListDefaults forKey:key];

    BOOL success = [self synchronize];
    if (!success) {
        ALog(@"Syncronization failed");
    }

}

- (void)removeLocusListItem:(LocusListItem *)locusListItem forKey:(NSString *)key {

    NSMutableArray *locusListDefaults = [[[self arrayForKey:key] mutableCopy] autorelease];
    [self removeObjectForKey:key];

    if (nil == locusListDefaults) {
        return;
    }

    NSDictionary *candidate = nil;
    for (NSDictionary *locusListDefault in locusListDefaults) {

        NSDictionary *dictionary = [locusListDefault objectForKey:[locusListItem userDefaultsKey]];
        if (nil != dictionary) {
            candidate = locusListDefault;
            break;
        }
    }

    if (nil == candidate) {
        return;
    }

    [locusListDefaults removeObject:candidate];
    [self setObject:locusListDefaults forKey:key];

    BOOL success = [self synchronize];
    if (!success) {
        ALog(@"Syncronization failed");
    }

}

- (void)registerDefaultsFromSettingsBundle {

    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        ALog(@"Could not find Settings.bundle");
        return;
    }

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];

    NSArray *preferenceSpecifiers = [settings objectForKey:@"PreferenceSpecifiers"];

    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferenceSpecifiers count]];

    for(NSDictionary *preferenceSpecifier in preferenceSpecifiers) {

        NSString *key = [preferenceSpecifier objectForKey:@"Key"];

        if(key && [[preferenceSpecifier allKeys] containsObject:@"DefaultValue"]) {

            [defaultsToRegister setObject:[preferenceSpecifier objectForKey:@"DefaultValue"] forKey:key];
        }
    }

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];

    [defaultsToRegister release];
}
@end