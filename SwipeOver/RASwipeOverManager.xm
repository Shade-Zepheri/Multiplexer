#import "headers.h"
#import "RASwipeOverManager.h"
#import "RASwipeOverOverlay.h"
#import "RAHostedAppView.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"

#define SCREEN_WIDTH (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) ? UIScreen.mainScreen.bounds.size.height : UIScreen.mainScreen.bounds.size.width)
#define VIEW_WIDTH(x) (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) ? x.frame.size.height : x.frame.size.width)

@interface RASwipeOverManager () {
	RASwipeOverOverlay *overlayWindow;

	CGFloat start;
}
@end

@implementation RASwipeOverManager
+(id) sharedInstance
{
	SHARED_INSTANCE(RASwipeOverManager);
}

-(BOOL) isUsingSwipeOver { return isUsingSwipeOver; }
-(void) showAppSelector { [overlayWindow showAppSelector]; }
-(BOOL) isEdgeViewShowing { return overlayWindow.frame.origin.x < SCREEN_WIDTH; }

-(void) startUsingSwipeOver
{
	start = 0;
	isUsingSwipeOver = YES;
	currentAppIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;

	[self createEdgeView];
}

-(void) stopUsingSwipeOver
{
	if (currentAppIdentifier)
	    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentAppIdentifier }, NO);   
	[overlayWindow removeOverlayFromUnderlyingAppImmediately];

	isUsingSwipeOver = NO;
	currentAppIdentifier = nil;

	[UIView animateWithDuration:0.3 animations:^{
		if ([[overlayWindow currentView] isKindOfClass:[RAHostedAppView class]])
			[((RAHostedAppView*)overlayWindow.currentView) viewWithTag:9903553].alpha = 0;

		overlayWindow.frame = CGRectMake(SCREEN_WIDTH, overlayWindow.frame.origin.y, overlayWindow.frame.size.width, overlayWindow.frame.size.height);
	} completion:^(BOOL _) {
		[self closeCurrentView];

		overlayWindow.hidden = YES;
		overlayWindow = nil;
	}];
}

-(void) createEdgeView
{
	overlayWindow = [[RASwipeOverOverlay alloc] initWithFrame:UIScreen.mainScreen.bounds];
	[overlayWindow makeKeyAndVisible];

	[overlayWindow showEnoughToDarkenUnderlyingApp];
	[self showApp:nil];
}

-(void) showApp:(NSString*)identifier
{
	[self closeCurrentView];

	SBApplication *app = nil;
    FBScene *scene = nil;

    if (identifier)
        app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
    else
    {
	    NSMutableArray *bundleIdentifiers = [[%c(SBAppSwitcherModel) sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary];
	    while (scene == nil && bundleIdentifiers.count > 0)
	    {
	        identifier = bundleIdentifiers[0];

	        if ([identifier isEqual:currentAppIdentifier])
	        {
	            [bundleIdentifiers removeObjectAtIndex:0];
	            continue;
	        }

	        app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
	        break;
	    }
    }

    if (identifier == nil || identifier.length == 0)
        return;

    RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:identifier];
    view.autosizesApp = YES;
    view.isTopApp = YES;
    view.allowHidingStatusBar = NO;
    view.frame = UIScreen.mainScreen.bounds;
    [view loadApp];

    UIView *detachView = [[UIView alloc] initWithFrame:CGRectMake(0, -20, view.frame.size.width, 20)];
    UITapGestureRecognizer *detachGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(detachViewAndCloseSwipeOver)];
    [detachView addGestureRecognizer:detachGesture];
    detachView.backgroundColor = [UIColor grayColor];
    detachView.userInteractionEnabled = YES;
    detachGesture.delegate = overlayWindow;
    detachView.tag = 9903553;
    [view addSubview:detachView];

    if (overlayWindow.isHidingUnderlyingApp == NO) // side-by-side
	    view.frame = CGRectMake(10, 0, view.frame.size.width, view.frame.size.height);
	else // overlay
	{
		view.frame = CGRectMake(SCREEN_WIDTH - 50, 0, view.frame.size.width, view.frame.size.height);

		CGFloat scale = (SCREEN_WIDTH - (50)) / [overlayWindow currentView].bounds.size.width;
		scale = 0.1; // MIN(MAX(scale, 0.1), 0.98);
		view.transform = CGAffineTransformMakeScale(scale, scale);
		view.center = (CGPoint) { SCREEN_WIDTH - (view.frame.size.width / 2), view.center.y };
	}

    view.tag = RASWIPEOVER_VIEW_TAG;
    [overlayWindow addSubview:view];

	[self updateClientSizes:YES];
}

-(void) closeCurrentView
{
	if ([[overlayWindow currentView] isKindOfClass:[RAHostedAppView class]])
	{
		[((RAHostedAppView*)overlayWindow.currentView) unloadApp];
	}
	[[overlayWindow currentView] removeFromSuperview];
}

-(void) convertSwipeOverViewToSideBySide
{
	if (currentAppIdentifier == nil)
	{
		[self stopUsingSwipeOver];
		return;
	}
	[overlayWindow currentView].transform = CGAffineTransformIdentity;
	[overlayWindow removeOverlayFromUnderlyingApp];
	[overlayWindow currentView].frame = (CGRect) { { 10, 0 }, [overlayWindow currentView].frame.size };
	overlayWindow.frame = CGRectOffset(overlayWindow.frame, SCREEN_WIDTH / 2, 0);
	[self sizeViewForTranslation:CGPointZero state:UIGestureRecognizerStateEnded]; // force it
	[self updateClientSizes:YES];
}

-(void) detachViewAndCloseSwipeOver
{
	SBApplication *app = ((RAHostedAppView*)overlayWindow.currentView).app;
	[self stopUsingSwipeOver];

	RADesktopWindow *desktop = RADesktopManager.sharedInstance.currentDesktop;
	[desktop createAppWindowForSBApplication:app animated:YES];
}

-(void) updateClientSizes:(BOOL)reloadAppSelectorSizeNow
{
	if (currentAppIdentifier)
	{
		CGFloat underWidth = [overlayWindow isHidingUnderlyingApp] ? -1 : overlayWindow.frame.origin.x;
		SEND_RESIZE_TO_UNDERLYING_APP(CGSizeMake(underWidth, -1));
	}
	
	if (overlayWindow.isShowingAppSelector && reloadAppSelectorSizeNow)
		[self showAppSelector];
	else if (overlayWindow.isHidingUnderlyingApp == NO) // Update swiped-over app in side-by-side mode. RAHostedAppView takes care of the app sizing if we resize the RAHostedAppView. 
		overlayWindow.currentView.frame = CGRectMake(10, 0, SCREEN_WIDTH - overlayWindow.frame.origin.x - 10, overlayWindow.currentView.frame.size.height);
}

-(void) sizeViewForTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state
{
	static CGFloat lastX = -1;
	UIView *targetView = [overlayWindow isHidingUnderlyingApp] ? [overlayWindow viewWithTag:RASWIPEOVER_VIEW_TAG] : overlayWindow;

	if (start == 0)
		start = targetView.center.x;
	
	if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled || state == UIGestureRecognizerStateFailed)
	{
		lastX = -1;
		start = 0;

		CGFloat scale = (SCREEN_WIDTH - targetView.frame.origin.x) / [overlayWindow currentView].bounds.size.width;
		if (scale <= 0.12 && (!CGPointEqualToPoint(translation, CGPointZero)))
		{
			[self stopUsingSwipeOver]; 
			return;
		}
	}
	else
	{
		//if (start + translation.x + (targetView.frame.size.width / 2) < UIScreen.mainScreen.bounds.size.width && [overlayWindow isHidingUnderlyingApp])
		//	return;
		//if (start + translation.x + targetView.frame.size.width - (targetView.frame.size.width / 2) < 0 && [overlayWindow isHidingUnderlyingApp] == NO)
		//	return;

		if (overlayWindow.isHidingUnderlyingApp && [[overlayWindow currentView] isKindOfClass:[UIScrollView class]] == NO)
		{
			if (lastX == -1)
				lastX = translation.x;
			CGFloat newScale = (lastX - translation.x) / SCREEN_WIDTH;
			lastX = translation.x; 

			newScale = newScale + sqrt(targetView.transform.a * targetView.transform.a + targetView.transform.c * targetView.transform.c);
			CGFloat scale = MIN(MAX(newScale, 0.1), 0.98);

			NSLog(@"[ReachApp] %f %f", newScale, scale);

			targetView.transform = CGAffineTransformMakeScale(scale, scale);
			targetView.center = (CGPoint) { SCREEN_WIDTH - (targetView.frame.size.width / 2), targetView.center.y };

			//CGFloat scale = (SCREEN_WIDTH - (start + translation.x)) / [overlayWindow currentView].bounds.size.width;
			//scale = MIN(MAX(scale, 0.1), 0.98);
			//targetView.transform = CGAffineTransformMakeScale(scale, scale);
			//targetView.center = (CGPoint) { SCREEN_WIDTH - (targetView.frame.size.width / 2), targetView.center.y };
		} 
		else
		{
			//targetView.frame = CGRectMake(SCREEN_WIDTH - (start + translation.x), 0, SCREEN_WIDTH - (SCREEN_WIDTH - start + translation.x), targetView.frame.size.height);
			targetView.center = (CGPoint) { start + translation.x, targetView.center.y };
		}
	}
	[self updateClientSizes:state == UIGestureRecognizerStateEnded];
}
@end