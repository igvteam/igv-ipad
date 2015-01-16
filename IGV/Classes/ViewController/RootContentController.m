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
//  RootContentController.m
//  NestedScrollviewSpike
//
//  Created by Douglass Turner on 01/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GenericPopupTrackMenuController.h"
#import "AlignmentRenderer.h"
#import "SEGRenderer.h"
#import "BarChartRenderer.h"
#import "TrackView.h"
#import "RefSeqFeatureSource.h"
#import "RootContentController.h"
#import "RefSeqTrackView.h"
#import "Cytoband.h"
#import "CytobandTrackView.h"
#import "IGVContext.h"
#import "LocusListItem.h"
#import "SpinnerContainer.h"
#import "TrackController.h"
#import "TrackContainerScrollView.h"
#import "Logging.h"
#import "RefSeqTrackController.h"
#import "IGVAppDelegate.h"
#import "IGVMath.h"
#import "GeneNameServiceController.h"
#import "BAMTrackController.h"
#import "LMResource.h"
#import "GenomeManager.h"
#import "IGVHelpful.h"
#import "CytobandIndicator.h"
#import "NSMutableDictionary+TrackController.h"
#import "NSArray+Cytoband.h"
#import "UINavigationItem+RootContentController.h"
#import "ZoomSlider.h"
#import "UIApplication+IGVApplication.h"
#import "FeatureInterval.h"
#import "RefSeqFeatureList.h"
#import "TrackDelegate.h"
#import "RulerView.h"
#import "TrackListController.h"
#import "GenomeNameListController.h"
#import "ChromosomeListController.h"
#import "FastaSequence.h"
#import "SEGFeatureSource.h"
#import "FeatureTrackView.h"
#import "BAMReader.h"
#import "AlignmentTrackView.h"

typedef enum {
    RootContentControllerUpdateUIAndFeaturesScrollViewDidScroll = 1,
    RootContentControllerUpdateUIAndFeaturesScrollViewDidZoom = 2
} RootContentControllerUpdateUIAndFeaturesMode;

NSString *const TrackDidFinishRenderingNotification = @"TrackDidFinishRenderingNotification";
NSString *const DidLaunchApplicationViaURLNotification = @"DidLaunchApplicationViaURLNotification";

NSTimeInterval const kScreenShotRevealDuration = 1.0/8.0;

@interface RootContentController ()

@property(nonatomic, retain) IBOutlet UIView *screenShot;
@property(nonatomic, retain) IBOutlet SpinnerContainer *spinnerContainer;
@property(nonatomic) BOOL isGenomeSelectionAtAppLaunch;

- (void)initializationHelper;

- (void)rootScrollViewDidEndScrolling:(RootScrollView *)rootScrollView;
- (void)rootScrollViewDidEndZooming:(RootScrollView *)rootScrollView;
- (void)rootScrollViewDidEnd:(RootScrollView *)rootScrollView;

- (void)zoomSliderValueChanged;
- (void)magnifyWithTapGesture:(UITapGestureRecognizer *)tapGesture;
- (void)minifyWithTapGesture:(UITapGestureRecognizer *)tapGesture;

- (void)zoomWithScaleFactor:(CGFloat)scaleFactor;

- (IBAction)segmentedControlHandlerWithSegmentedControl:(UISegmentedControl *)aSegmentedControl;

- (void)selectGenomeContinuationGenomeManager:(GenomeManager *)genomeManager locusListItem:(LocusListItem *)locusListItem;

- (BOOL)didCaptureScreenShot;
- (void)revealScreenDiscardScreenShotWithCompletion:(void (^)(BOOL))completion;
@end

@implementation RootContentController

@synthesize locusTextField;
@synthesize cytobandTrack;
@synthesize rootScrollView = _rootScrollView;
@synthesize trackContainerScrollView;
@synthesize refSeqTrack;
@synthesize locusListPopoverController;
@synthesize trackControllers;
@synthesize allowOrientationChange;
@synthesize geneNameServicePopoverController;
@synthesize spinnerContainer;
@synthesize trackListPopoverController;
@synthesize genomeListPopoverController;
@synthesize screenShot;
@synthesize remainingTrackRenderings;
@synthesize isGenomeSelectionAtAppLaunch = _isGenomeSelectionAtAppLaunch;
@synthesize rulerView = _rulerView;
@synthesize sessionListPopoverController = _sessionListPopoverController;

#pragma mark -
#pragma mark - Death / Birth

@synthesize trackMenuPopoverController = _trackMenuPopoverController;
@synthesize rootControllerViewLocation = _rootControllerViewLocation;

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:GenomeSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TrackDidFinishRenderingNotification object:nil];

    self.locusTextField = nil;
    self.locusListPopoverController = nil;
    self.sessionListPopoverController = nil;
    self.spinnerContainer = nil;
    self.cytobandTrack = nil;
    self.rootScrollView = nil;
    self.trackContainerScrollView = nil;
    self.rulerView = nil;
    self.refSeqTrack = nil;
    self.trackControllers = nil;
    self.geneNameServicePopoverController = nil;
    self.trackListPopoverController = nil;
    self.genomeListPopoverController = nil;
    self.screenShot = nil;

    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (nil != self) {

        [self initializationHelper];
    }

    return self;
}

- (void)awakeFromNib {
    [self initializationHelper];
}

- (void)initializationHelper {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genomeSelectionDidChangeWithNotification:) name:GenomeSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDidFinishRenderingWithNotification:) name:TrackDidFinishRenderingNotification object:nil];

    self.rootScrollView.scrollViewZoomScaleBeingSet = NO;
    self.allowOrientationChange = YES;
    self.isGenomeSelectionAtAppLaunch = YES;
}

#pragma mark -
#pragma mark - View lifecycle

- (void)viewDidLoad {

    [super viewDidLoad];

    [self.navigationItem configureWithRootContentController:self];

    [self.rootScrollView configureWithRootContentController:self];

    self.trackContainerScrollView.contentSize = self.trackContainerScrollView.bounds.size;

//    ///////////////////////////////////////////////////
//    self.trackContainerScrollView.layer.contents = (id) [UIImage imageNamed:@"kidsIcons"].CGImage;
//    ///////////////////////////////////////////////////

    self.spinnerContainer.center = self.rootScrollView.center;

    self.remainingTrackRenderings = 0;

    NSString *queueName = [NSString stringWithFormat:@"org.broadinstitute.igv.%@", [RootContentController class]];
    dispatch_async(dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self spinnerSpin:YES];
        });

        NSError *error = nil;
        BOOL success = [[GenomeManager sharedGenomeManager] loadGenomeStubsWithGenomePath:kGenomesFilePath error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self spinnerSpin:NO];
        });

        if (!success) {

            NSString *errorMessage = (error) ? [error localizedDescription] : @"Bad Things";
            [[IGVHelpful sharedIGVHelpful] presentErrorMessage:errorMessage];

        } else {

            dispatch_async(dispatch_get_main_queue(), ^{
                [self selectGenomeWithGenomeManager:[GenomeManager sharedGenomeManager]
                                      locusListItem:nil];
            });

        }

    });

}

#pragma mark -
#pragma mark - Interface Orientation Management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return self.allowOrientationChange;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

    self.rootScrollView.contentSize = CGSizeMake(self.rootScrollView.contentSize.width, CGRectGetHeight(self.rootScrollView.contentContainer.bounds));

    CGPoint c = self.rootScrollView.center;
    self.spinnerContainer.center = c;

    LocusListItem *currentLocusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];

    if (nil == currentLocusListItem) {
        return;
    }

    LocusListItem *locusListItem = nil;
    if ([currentLocusListItem length] >= [[[GenomeManager sharedGenomeManager] currentChromosomeExtent] length]) {

        locusListItem = [[[LocusListItem alloc] initWithLocus:[IGVContext sharedIGVContext].chromosomeName
                                                        label:nil
                                              locusListFormat:LocusListFormatChrFullExtent
                                                   genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

    } else {

        locusListItem = currentLocusListItem;
    }

    [self.rootScrollView setContentOffsetWithLocusListItem:locusListItem disableUI:YES];
    [self.trackControllers renderAllTracks];

}

#pragma mark -
#pragma mark - RootContentController methods

- (NSMutableDictionary *)trackControllers {

    if (nil == trackControllers) {

        self.trackControllers = [NSMutableDictionary dictionary];
    }

    return trackControllers;
}

- (UIPopoverController *)genomeListPopoverController {

    if (nil == genomeListPopoverController) {

        UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"GenomeList" bundle:nil] instantiateViewControllerWithIdentifier:@"GenomeListNavController"];
        self.genomeListPopoverController = [[[UIPopoverController alloc] initWithContentViewController:navigationController] autorelease];
        self.genomeListPopoverController.delegate = self;
    }

    return genomeListPopoverController;
}

- (UIPopoverController *)trackListPopoverController {

    if (nil == trackListPopoverController) {

        UINavigationController *navigationController = [[[UINib nibWithNibName:@"TrackListNavigationController" bundle:nil] instantiateWithOwner:nil options:nil] objectAtIndex:0];
        navigationController.preferredContentSize= CGSizeMake(512, 400);
        navigationController.topViewController.preferredContentSize = navigationController.preferredContentSize;
//        navigationController.topViewController.preferredContentSize = CGSizeMake(512, 400);

        self.trackListPopoverController = [[[UIPopoverController alloc] initWithContentViewController:navigationController] autorelease];
        self.trackListPopoverController.delegate = self;
    }

    return trackListPopoverController;
}

- (UIPopoverController *)locusListPopoverController {

    if (nil == locusListPopoverController) {

        UINavigationController *navigationController = [[[UINib nibWithNibName:@"LocusListNavigationController" bundle:nil] instantiateWithOwner:nil options:nil] objectAtIndex:0];
        navigationController.preferredContentSize= CGSizeMake(512, 400);
        navigationController.topViewController.preferredContentSize = navigationController.preferredContentSize;
//        navigationController.topViewController.preferredContentSize = CGSizeMake(512, 400);

        self.locusListPopoverController = [[[UIPopoverController alloc] initWithContentViewController:navigationController] autorelease];
        self.locusListPopoverController.delegate = self;
    }

    return locusListPopoverController;
}

- (UIPopoverController *)sessionListPopoverController {

    if (nil == _sessionListPopoverController) {

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SessionStoryboard" bundle:nil];
        UINavigationController *navigationController = [storyboard instantiateInitialViewController];
        navigationController.preferredContentSize= CGSizeMake(512, 400);
        navigationController.topViewController.preferredContentSize = navigationController.preferredContentSize;
//        navigationController.topViewController.preferredContentSize = CGSizeMake(512, 400);

        self.sessionListPopoverController = [[[UIPopoverController alloc] initWithContentViewController:navigationController] autorelease];
        self.sessionListPopoverController.delegate = self;
    }

    return _sessionListPopoverController;
}

#pragma mark -
#pragma mark PopoverControllerDelegate Method Implementation

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

    // Deselect current segment
    UISegmentedControl *segmentedControl = (UISegmentedControl *) self.navigationItem.leftBarButtonItem.customView;
    segmentedControl.selectedSegmentIndex = -1;

    UIViewController *viewController = popoverController.contentViewController;
    if ([viewController isMemberOfClass:[UINavigationController class]]) {

        UINavigationController *navigationController = (UINavigationController *) viewController;
        UIViewController *topViewController = navigationController.topViewController;
        if ([topViewController isMemberOfClass:[TrackListController class]]) {

            [navigationController popToRootViewControllerAnimated:NO];
        } else if ([topViewController isMemberOfClass:[ChromosomeListController class]]) {

            [navigationController popToRootViewControllerAnimated:NO];
        }
    }

}

#pragma mark -
#pragma mark Track Popup Method

- (void)presentPopupTrackMenuWithLongPress:(UILongPressGestureRecognizer *)longPress {

    if (UIGestureRecognizerStateBegan != longPress.state) {
        return;
    }

    self.rootControllerViewLocation = [longPress.view convertPoint:[longPress locationInView:longPress.view]
                                                                   toView:self.view];


    NSMutableDictionary *customMenus = [NSMutableDictionary dictionary];
    [customMenus setObject:@"WIGTrackMenu"    forKey:NSStringFromClass([BarChartRenderer  class])];
    [customMenus setObject:@"BAMSEGTrackMenu" forKey:NSStringFromClass([SEGRenderer       class])];
    [customMenus setObject:@"BAMSEGTrackMenu" forKey:NSStringFromClass([AlignmentRenderer class])];

    TrackView *track = (TrackView *) longPress.view;
    id key = NSStringFromClass([track.renderer class]);

    NSString *vc = [customMenus objectForKey:key];
    GenericPopupTrackMenuController *genericPopupTrackMenuController = [[UIStoryboard storyboardWithName:@"TrackPopupMenu" bundle:nil] instantiateViewControllerWithIdentifier:(vc) ? vc :@"GenericTrackMenu"];
    genericPopupTrackMenuController.trackDelegate = track.trackDelegate;

    UINavigationController *navigationController = [[UIStoryboard storyboardWithName:@"TrackPopupMenu" bundle:nil] instantiateViewControllerWithIdentifier:@"TrackMenuPopoverNavController"];
    [navigationController pushViewController:genericPopupTrackMenuController animated:NO];

    self.trackMenuPopoverController = [[[UIPopoverController alloc] initWithContentViewController:navigationController] autorelease];
    [self.trackMenuPopoverController presentPopoverFromRect:[IGVMath rectWithCenter:[longPress locationInView:longPress.view] size:CGSizeMake(2, 2)]
                                                     inView:longPress.view
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:YES];

}

#pragma mark -
#pragma mark - RootContentController methods

- (void)enableTracksWithResources:(NSArray *)resources appLaunchLocusCentroid:(NSNumber *)appLaunchLocusCentroid {

    if (![IGVHelpful networkStatus]) {
        [[IGVHelpful sharedIGVHelpful] presentErrorMessage:[NSString stringWithFormat:@"ERROR. Network unavailable."]];
        return;
    }

    NSMutableArray *uniqueResources = [NSMutableArray array];
    for (LMResource *resource in resources) {

        if (nil != [self.trackControllers objectForKey:resource.filePath]) {
            ALog(@"Ignore attempted add of duplicate track %@", resource);
        } else {
            [uniqueResources addObject:resource];
        }
    }

    [[UIApplication sharedIGVAppDelegate] disableUserInteraction];

    self.remainingTrackRenderings = [uniqueResources count];

    NSMutableSet *bamResources = [NSMutableSet setWithSet:[uniqueResources bamResourceSet]];
    ALog(@"unique resources %d", [uniqueResources count]);
    for (LMResource *resource in uniqueResources) {

        if ([bamResources containsObject:resource]) {










            // TODO - dat - why does this construction not work?
//           BAMReader *bamReader = [[[BAMReader alloc] initWithPath:resource.path] autorelease];
//            if (nil == bamReader) {
//                --(self.remainingTrackRenderings);
//                [bamResources removeObject:resource];
//                continue;
//            }
//
//            AlignmentTrackView *alignmentTrack = [[[AlignmentTrackView alloc] initWithFrame:[AlignmentTrackView trackFrame]
//                                                                                   resource:resource
//                                                                              trackDelegate:[[[TrackDelegate alloc] init] autorelease]
//                                                                            trackController:nil] autorelease];
//
//            BAMTrackController *bamTrackController = [[[BAMTrackController alloc] initWithTrack:alignmentTrack] autorelease];
//            alignmentTrack.trackController = bamTrackController;












            BAMTrackController *bamTrackController = [[[BAMTrackController alloc] initWithResource:resource] autorelease];
            if (nil == bamTrackController) {
                --(self.remainingTrackRenderings);
                [bamResources removeObject:resource];
                continue;
            }















            bamTrackController.appLaunchLocusCentroid = appLaunchLocusCentroid;


            [self.trackControllers setObject:bamTrackController forKey:resource.filePath];

        } else {

            BaseFeatureSource *featureSource = [BaseFeatureSource featureSourceWithResource:resource];
            if (nil == featureSource) {
                --(self.remainingTrackRenderings);
                continue;
            }

            NSString *trackClassString = ([featureSource isMemberOfClass:[SEGFeatureSource class]]) ? @"SEGTrackView" : @"FeatureTrackView";
            Class trackClass = NSClassFromString(trackClassString);

            FeatureTrackView *featureTrack = [[[trackClass alloc] initWithFrame:[trackClass trackFrame]
                                                                       resource:resource
                                                                  trackDelegate:[[[TrackDelegate alloc] init] autorelease]] autorelease];

            featureTrack.featureSource = featureSource;
            TrackController *trackController = [[[TrackController alloc] initWithTrack:featureTrack] autorelease];

            [self.trackControllers setObject:trackController forKey:resource.filePath];

        }
    }

    if (0 == [uniqueResources count]) {
        self.remainingTrackRenderings = 0;
        [[UIApplication sharedIGVAppDelegate] enableUserInteraction];
        return;
    }

}

- (void)discardTrackWithResource:(LMResource *)resource {

    TrackController *trackController = [self.trackControllers objectForKey:resource.filePath];

    TrackView *track = [self.trackContainerScrollView trackWithTrackController:trackController];

    [self.trackControllers removeObjectForKey:resource.filePath];

    [self.trackContainerScrollView discardTrack:track];

}

- (void)selectLocusListItem:(LocusListItem *)locusListItem {

    if (nil == locusListItem) {
        return;
    }

    [IGVContext sharedIGVContext].chromosomeName = locusListItem.chromosomeName;
    [self.rootScrollView setContentOffsetWithLocusListItem:locusListItem disableUI:YES];
    [self.trackControllers renderAllTracks];

}

#pragma mark -
#pragma mark - ScrollView Delegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.rootScrollView.contentContainer;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if (RootScrollViewPanCriteriaUnmet == [self.rootScrollView panCriteria]) {
        return;
    }

    [self rootScrollViewDidEndScrolling:self.rootScrollView];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
//    ALog(@"%@", scrollView);
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {

//    ALog(@"%@", scrollView);

    LocusListItem *currentLocusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];
    self.rootScrollView.maximumZoomScale = MIN([self.rootScrollView derivedMaximumZoomScaleWithCurrentLocusListItem:currentLocusListItem], kRootScrollViewDefaultMaximumZoomScale);
    self.rootScrollView.minimumZoomScale = MAX([self.rootScrollView derivedMinimumZoomScaleWithCurrentLocusListItem:currentLocusListItem], kRootScrollViewDefaultMinimumZoomScale);

    [self.trackContainerScrollView hideTrackLabels:YES];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    [self rootScrollViewDidEndZooming:self.rootScrollView];
}

#pragma mark -
#pragma mark - RootContentController ScrollView Methods

- (void)rootScrollViewDidEndScrolling:(RootScrollView *)rootScrollView {
    [self rootScrollViewDidEnd:rootScrollView];
}

- (void)rootScrollViewDidEndZooming:(RootScrollView *)rootScrollView {
    [self rootScrollViewDidEnd:rootScrollView];
}

- (void)rootScrollViewDidEnd:(RootScrollView *)rootScrollView {

    [self captureScreenShot];

    LocusListItem *currentLocusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];

    LocusListItem *locusListItem = nil;

    if (LocusListFormatChrFullExtent == currentLocusListItem.locusListFormat && [rootScrollView pinchGestureIsMagnifying:rootScrollView.pinchGestureRecognizer]) {

        self.cytobandTrack.indicator.hidden = YES;
        self.locusTextField.text = [NSString stringWithFormat:@"chr%@", [IGVContext sharedIGVContext].chromosomeName];

        locusListItem = [[[LocusListItem alloc] initWithLocus:currentLocusListItem.chromosomeName
                                                        label:nil
                                              locusListFormat:LocusListFormatChrFullExtent
                                                   genomeName:currentLocusListItem.genome] autorelease];
    }  else {

        locusListItem = currentLocusListItem;
    }

    [rootScrollView setContentOffsetWithLocusListItem:locusListItem disableUI:YES];
    [self.trackControllers renderAllTracks];
}

#pragma mark -
#pragma mark - UITextFieldDelegate Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];

    NSString *string = [textField.text removeHeadTailWhitespace];

    LocusListFormat locusListFormat = [string format];

    if (LocusListFormatInvalid == locusListFormat) {

        dispatch_queue_t cloudQueue = dispatch_queue_create("org.broadinstitute.igv.gene_name_lookup", DISPATCH_QUEUE_SERIAL);
        NSString *urlString = [NSString stringWithFormat:@"http://www.broadinstitute.org/webservices/igv/locus?genome=%@&name=%@", [GenomeManager sharedGenomeManager].currentGenomeName, string];

        dispatch_async(cloudQueue, ^{

            dispatch_async(dispatch_get_main_queue(),
                    ^{
                        [self spinnerSpin:YES];
                    });

            NSArray *results = [GeneNameServiceController geneNameLookupResultsWithURLString:urlString];

            if (nil != results) {

                if ([results count] > 0) {

                    if (1 == [results count]) {

                        NSString *locus = [[results objectAtIndex:0] objectAtIndex:1];
                        LocusListFormat format = [locus format];
                        if (LocusListFormatInvalid != format) {

                            LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:locus
                                                                                           label:@""
                                                                                 locusListFormat:format
                                                                                      genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

                            dispatch_async(dispatch_get_main_queue(),
                                    ^{
                                        [self selectLocusListItem:locusListItem];
                                    });

                        }

                    } else {

                        GeneNameServiceController *geneNameServiceController = [[[GeneNameServiceController alloc] initWithGenes:results NibName:nil bundle:nil] autorelease];
                        self.geneNameServicePopoverController = [[[UIPopoverController alloc] initWithContentViewController:geneNameServiceController] autorelease];
                        self.geneNameServicePopoverController.delegate = self;

                        dispatch_async(dispatch_get_main_queue(),
                                ^{

                                    UINavigationItem *navigationItem = self.navigationController.navigationBar.topItem;

                                    CGFloat x = CGRectGetMidX([navigationItem.titleView bounds]);
                                    CGFloat y = CGRectGetMaxY([navigationItem.titleView bounds]);

                                    [self.geneNameServicePopoverController presentPopoverFromRect:[IGVMath rectWithCenter:CGPointMake(x, y) size:CGSizeMake(2, 2)]
                                                                                           inView:navigationItem.titleView
                                                                         permittedArrowDirections:UIPopoverArrowDirectionUp
                                                                                         animated:YES];
                                });

                    }

                }
            }

            dispatch_async(dispatch_get_main_queue(),
                    ^{
                        [self spinnerSpin:NO];
                    });

        });

    } else {

        LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:string
                                                                       label:@""
                                                             locusListFormat:locusListFormat
                                                                  genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

        // Add
        locusListItem.start = MAX(locusListItem.start - 1, 0);
        [self selectLocusListItem:locusListItem];

    }

    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.locusTextField becomeFirstResponder];
}

#pragma mark -
#pragma mark - Methods

- (void)spinnerSpin:(BOOL)spin {
    [self.spinnerContainer spinnerSpin:spin];
}

#pragma mark -
#pragma mark - Zoom Slider Methods

- (void)zoomSliderValueChanged {

    [self captureScreenShot];

    ZoomSlider *zoomSlider = (ZoomSlider *)self.navigationItem.rightBarButtonItem.customView;

    double scaledLocusLength;
    LocusListItem *locusListItem = nil;

    if ([zoomSlider isNearMinimumValue]) {

        ALog(@"near minimum");
        scaledLocusLength = CGRectGetWidth([self.rootScrollView bounds]) / kRootScrollViewMaximumPointsPerBases;
        locusListItem = [[[IGVContext sharedIGVContext] currentLocusListItem] locusListItemWithLength:(long long int)scaledLocusLength];

    } else if ([zoomSlider isNearMaximumValue]) {

        ALog(@"near maximum");
        LocusListItem *lli = [[IGVContext sharedIGVContext] currentLocusListItem];
        locusListItem = [[[LocusListItem alloc] initWithLocus:lli.chromosomeName label:nil locusListFormat:LocusListFormatChrFullExtent genomeName:lli.genome] autorelease];

    } else {

        scaledLocusLength = [zoomSlider valueLogarithmic0to1] * [[[GenomeManager sharedGenomeManager] currentChromosomeExtent] length];
        locusListItem = [[[IGVContext sharedIGVContext] currentLocusListItem] locusListItemWithLength:(long long int)scaledLocusLength];
    }

    [self.rootScrollView setContentOffsetWithLocusListItem:locusListItem disableUI:YES];
    [self.trackControllers renderAllTracks];

}

- (void)updateZoomSlider {
    ZoomSlider *zoomSlider = (ZoomSlider *) self.navigationItem.rightBarButtonItem.customView;
    [zoomSlider updateWithLinearScaleFactor:[[IGVContext sharedIGVContext] chromosomeZoomWithLocusListItem:[[IGVContext sharedIGVContext] currentLocusListItem]]];
}

#pragma mark -
#pragma mark - Magnify/Minify Tap Gesture Callbacks

- (void)magnifyWithTapGesture:(UITapGestureRecognizer *)tapGesture {
    [self zoomWithScaleFactor:0.5];
}

- (void)minifyWithTapGesture:(UITapGestureRecognizer *)tapGesture {
    [self zoomWithScaleFactor:2.0];
}

- (void)zoomWithScaleFactor:(CGFloat)scaleFactor {

    LocusListItem *currentLocusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];
    LocusListItem *zoomed = [currentLocusListItem locusListItemWithScaleFactor:scaleFactor];

    if (nil == zoomed) {
        return;
    }

    [self captureScreenShot];

    [self.rootScrollView setContentOffsetWithLocusListItem:zoomed disableUI:YES];
    [self.trackControllers renderAllTracks];
}

#pragma mark -
#pragma mark - Screenshots

- (void)captureScreenShot {

    UIImage *screenShotImage = [IGVHelpful imageScreenShotWithView:self.view];

    self.screenShot.layer.contents = (id) screenShotImage.CGImage;
    [self.view bringSubviewToFront:self.screenShot];
    [self.view insertSubview:self.screenShot belowSubview:self.spinnerContainer];
}

- (BOOL)didCaptureScreenShot {
    return nil != self.screenShot.layer.contents;
}

- (void)revealScreenDiscardScreenShotWithCompletion:(void (^)(BOOL))completion {

//    ALog(@"begin screen capture reveal");
    [UIView animateWithDuration:kScreenShotRevealDuration delay:0.0
//                        options:UIViewAnimationOptionCurveEaseInOut
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.screenShot.alpha = 0;
                     }

                     completion:completion
    ];

}

#pragma mark -
#pragma mark NavigationBar Button Callbacks

- (IBAction)segmentedControlHandlerWithSegmentedControl:(UISegmentedControl *)aSegmentedControl {

    NSArray *popovers = [NSArray arrayWithObjects:self.genomeListPopoverController, self.trackListPopoverController, self.sessionListPopoverController, nil];

    for (UIPopoverController *popover in popovers) {
        if (popover.isPopoverVisible) {
            [popover dismissPopoverAnimated:YES];
        }
    }

    UIPopoverController *popoverController = (UIPopoverController *) [popovers objectAtIndex:(NSUInteger) aSegmentedControl.selectedSegmentIndex];

    CGFloat originY = CGRectGetMaxY(aSegmentedControl.bounds);

    CGFloat dx = 1.0 / (CGFloat) aSegmentedControl.numberOfSegments;
    CGFloat xOffset = dx / 2.0;
    CGFloat originX = (xOffset + aSegmentedControl.selectedSegmentIndex * dx) * CGRectGetWidth(aSegmentedControl.bounds);

    [popoverController presentPopoverFromRect:[IGVMath rectWithCenter:CGPointMake(originX, originY) size:CGSizeMake(2, 2)] inView:aSegmentedControl permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];

}

#pragma mark - Notification Callbacks

- (void)genomeSelectionDidChangeWithNotification:(NSNotification *)notification {

    [self.trackControllers removeAllTracks];

    UINavigationController *navigationController = (UINavigationController *)self.trackListPopoverController.contentViewController;
    [navigationController popToRootViewControllerAnimated:NO];

    NSDictionary *dictionary = notification.object;

    [self selectGenomeWithGenomeManager:[dictionary objectForKey:@"genomeManager"]
                          locusListItem:[dictionary objectForKey:@"locusListItem"]];
}

- (void)selectGenomeWithGenomeManager:(GenomeManager *)genomeManager locusListItem:(LocusListItem *)locusListItem {

    dispatch_async(genomeManager.dataRetrievalQueue, ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedIGVAppDelegate] disableUserInteraction];
        });

        __block NSError *error = nil;
        __block BOOL success = NO;

        NSDictionary *genomeStub = [genomeManager currentGenomeStub];

        LMResource *resource = (nil == [genomeStub objectForKey:@"sequenceLocation"]) ? nil : [LMResource resourceWithName:nil filePath:[genomeStub objectForKey:@"sequenceLocation"] indexPath:nil];

        self.refSeqTrack.resource = resource;
        self.refSeqTrack.featureList = [[[RefSeqFeatureList alloc] init] autorelease];
        self.refSeqTrack.featureSource = [[[RefSeqFeatureSource alloc] init] autorelease];

        RefSeqTrackController *refSeqTrackController = [[[RefSeqTrackController alloc] initWithTrack:self.refSeqTrack] autorelease];

        [self.trackControllers setObject:refSeqTrackController
                                  forKey:NSStringFromClass([RefSeqTrackController class])];

        if ([genomeManager cytobandExistsForGenomeName:genomeManager.currentGenomeName]) {

            error = nil;
            success = [genomeManager loadCytobandWithGenomeName:genomeManager.currentGenomeName error:&error];
            if (!success) {
                ALog(@"%@", [error localizedDescription]);
            }

        }

        dispatch_async(dispatch_get_main_queue(), ^{

            if ([genomeManager currentFastaSequence]) {

                [[genomeManager currentFastaSequence] loadFastaIndexWithContinuation:^() {

                    [self selectGenomeContinuationGenomeManager:genomeManager locusListItem:locusListItem];

                }];

            }  else {

                [self selectGenomeContinuationGenomeManager:genomeManager locusListItem:locusListItem];
            }

        });

    });

}

- (void)selectGenomeContinuationGenomeManager:(GenomeManager *)genomeManager locusListItem:(LocusListItem *)locusListItem {

    LocusListItem *lli = locusListItem;
    if (nil == lli) {

        lli = [[[LocusListItem alloc] initWithLocus:[genomeManager firstChromosomeName]
                                              label:nil
                                    locusListFormat:LocusListFormatChrFullExtent
                                         genomeName:genomeManager.currentGenomeName] autorelease];
    }

    [IGVContext sharedIGVContext].chromosomeName = lli.chromosomeName;

    [self.rootScrollView setContentOffsetWithLocusListItem:lli
                                                 disableUI:NO];

    NSDictionary *genomeStub = [genomeManager currentGenomeStub];
    if (nil != [genomeStub objectForKey:kGeneFileKey]) {

        LMResource *resource = [LMResource resourceWithName:kGeneTrackName filePath:[genomeStub objectForKey:kGeneFileKey] indexPath:nil];


        BaseFeatureSource *featureSource = [BaseFeatureSource featureSourceWithResource:resource];
        TrackController *geneTrackController = nil;
        if (nil != featureSource) {

            NSString *trackClassString = ([featureSource isMemberOfClass:[SEGFeatureSource class]]) ? @"SEGTrackView" : @"FeatureTrackView";
            Class trackClass = NSClassFromString(trackClassString);

            FeatureTrackView *featureTrack = [[[trackClass alloc] initWithFrame:[trackClass trackFrame]
                                                                       resource:resource
                                                                  trackDelegate:[[[TrackDelegate alloc] init] autorelease]] autorelease];

            featureTrack.featureSource = featureSource;
            geneTrackController = [[[TrackController alloc] initWithTrack:featureTrack] autorelease];

        }

        if (nil != geneTrackController) {
            self.trackContainerScrollView.geneTrack = geneTrackController.track;
            [self.trackControllers setObject:geneTrackController forKey:resource.filePath];
        }
    }

    self.cytobandTrack.indicator.hidden = YES;
    self.locusTextField.text = [NSString stringWithFormat:@"chr%@", [IGVContext sharedIGVContext].chromosomeName];

    [self.trackControllers renderAllTracks];
}

- (void)unwindViewControllerStackWithPopoverController:(UIPopoverController *)popoverController {

    UINavigationController *navController = (UINavigationController *)popoverController.contentViewController;
    [navController popToRootViewControllerAnimated:NO];
}

- (void)trackDidFinishRenderingWithNotification:(NSNotification *)notification {

    self.remainingTrackRenderings -= 1;
    TrackView *track = [notification object];
//    ALog(@"%@ finished rendering. %d remaining%@.", track, self.remainingTrackRenderings, (0 == self.remainingTrackRenderings) ? @". Will post Launch App Via URL Notification" : @"");

    if (0 == self.remainingTrackRenderings) {

        if ([self didCaptureScreenShot]) {

            [self revealScreenDiscardScreenShotWithCompletion:^(BOOL finished) {

                [self.view sendSubviewToBack:self.screenShot];
                self.screenShot.alpha = 1;
                self.screenShot.layer.contents = nil;

                [self.trackContainerScrollView hideTrackLabels:NO];

                [self updateZoomSlider];
            }];

        }

        [[UIApplication sharedIGVAppDelegate] enableUserInteraction];
        [[NSNotificationCenter defaultCenter] postNotificationName:DidLaunchApplicationViaURLNotification object:nil];
    }

}

#pragma mark - Nib Name

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}

@end