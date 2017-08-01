#import "headers.h"
#import "RASwipeOverManager.h"
#import "RASwipeOverOverlay.h"
#import "RAHostedAppView.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "RAMessagingServer.h"
#import "RAResourceImageProvider.h"
#import "RAAppSelectorView.h"
#import "RAAppSwitcherModelWrapper.h"
#import "RAOrientationLocker.h"
#import "UIAlertController+Window.h"

extern int rotationDegsForOrientation(int o);

//#define SCREEN_WIDTH (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? UIScreen.mainScreen.bounds.size.height : UIScreen.mainScreen.bounds.size.width)
#define SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].RA_interfaceOrientedBounds)

@interface RASwipeOverManager () {
	RASwipeOverOverlay *overlayWindow;

	CGFloat start;

	BOOL didWantOrientationEvents;
}
@end

@implementation RASwipeOverManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE(RASwipeOverManager);
}

- (BOOL)isUsingSwipeOver {
	return isUsingSwipeOver;
}

- (void)showAppSelector {
	[overlayWindow showAppSelector];
}

- (BOOL)isEdgeViewShowing {
	return overlayWindow.frame.origin.x < SCREEN_WIDTH;
}

- (void)startUsingSwipeOver {
	start = 0;
	isUsingSwipeOver = YES;
	currentAppIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;

	[self createEdgeView];

	[RAOrientationLocker lockOrientation];
}

- (void)stopUsingSwipeOver {
	[overlayWindow removeOverlayFromUnderlyingAppImmediately];
	if (currentAppIdentifier) {
		[[RAMessagingServer sharedInstance] endResizingApp:currentAppIdentifier completion:nil];
		[[RAMessagingServer sharedInstance] setShouldUseExternalKeyboard:YES forApp:currentAppIdentifier completion:nil];
	}

	[RAOrientationLocker unlockOrientation];

	isUsingSwipeOver = NO;
	currentAppIdentifier = nil;

	CGRect frame = overlayWindow.frame;
	CGPoint newCenter = overlayWindow.center;
	switch ([[UIApplication sharedApplication] statusBarOrientation]) {
	  case UIInterfaceOrientationPortrait:
			newCenter = CGPointMake((frame.size.width * 3) / 2, newCenter.y);
			break;
	  case UIInterfaceOrientationPortraitUpsideDown:
			newCenter = CGPointMake(frame.size.width / -2, newCenter.y);
			break;
	  case UIInterfaceOrientationLandscapeLeft:
			newCenter = CGPointMake(newCenter.x, frame.size.width / -2);
			break;
	  case UIInterfaceOrientationLandscapeRight:
			newCenter = CGPointMake(newCenter.x, (frame.size.width * 3) / 2);
			break;
	}

	[UIView animateWithDuration:0.3 animations:^{
		if ([[overlayWindow currentView] isKindOfClass:[RAHostedAppView class]]) {
			[((RAHostedAppView *)overlayWindow.currentView) viewWithTag:9903553].alpha = 0;
		}
		overlayWindow.center = newCenter;
	} completion:^(BOOL finished) {
		if (finished) {
			[self closeCurrentView];

			overlayWindow.hidden = YES;
			overlayWindow = nil;
		}
	}];
}

- (void)createEdgeView {
	overlayWindow = [[RASwipeOverOverlay alloc] initWithFrame:[UIScreen mainScreen].RA_interfaceOrientedBounds];
	if (!IS_IOS_OR_NEWER(iOS_9_0)) {
		[overlayWindow _rotateWindowToOrientation:[UIApplication sharedApplication].statusBarOrientation updateStatusBar:YES duration:0.001 skipCallbacks:NO];
	}
	[overlayWindow showEnoughToDarkenUnderlyingApp];
	[overlayWindow makeKeyAndVisible];
	[overlayWindow updateForOrientation:[UIApplication sharedApplication].statusBarOrientation];

	[self showApp:nil];
}

- (void)showApp:(NSString *)identifier {
	[self closeCurrentView];

	SBApplication *app = nil;
	FBScene *scene = nil;

	if (identifier) {
		app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
	} else {
	  NSMutableArray *bundleIdentifiers = [[RAAppSwitcherModelWrapper appSwitcherAppIdentiferList] mutableCopy];
	  while (!scene && bundleIdentifiers.count > 0) {
	    identifier = bundleIdentifiers[0];

	    if ([identifier isEqualToString:currentAppIdentifier]) {
	      [bundleIdentifiers removeObjectAtIndex:0];
	      continue;
	    }

	    app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
	    break;
	  }
	}

	if (app) {
		[RAAppSwitcherModelWrapper addToFront:app];
	}

	if (!identifier || identifier.length == 0) {
		return;
	}

	RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:identifier];
	view.autosizesApp = NO;
	if (!overlayWindow.isHidingUnderlyingApp) {
		view.autosizesApp = YES;
	}
	view.shouldUseExternalKeyboard = YES;
	view.allowHidingStatusBar = NO;
	view.frame = [UIScreen mainScreen]._referenceBounds;
	view.showSplashscreenInsteadOfSpinner = YES;
	view.renderWallpaper = YES;
	[view rotateToOrientation:UIInterfaceOrientationPortrait];
	[view loadApp];

	UIImageView *detachView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -20, view.frame.size.width, 20)];
	detachView.image = [[RAResourceImageProvider imageForFilename:@"SwipeOverDetachImage" constrainedToSize:CGSizeMake(97, 28)] _flatImageWithColor:THEMED(swipeOverDetachImageColor)];
	detachView.contentMode = UIViewContentModeScaleAspectFit;
	UITapGestureRecognizer *detachGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(detachViewAndCloseSwipeOver)];
	[detachView addGestureRecognizer:detachGesture];
	detachView.backgroundColor = THEMED(swipeOverDetachBarColor);
	detachView.userInteractionEnabled = YES;
	detachGesture.delegate = overlayWindow;
	detachView.tag = 9903553;
	[view addSubview:detachView];

	if (!overlayWindow.isHidingUnderlyingApp) { // side-by-side
		view.frame = CGRectMake(10, 0, view.frame.size.width, view.frame.size.height);
	} else { // overlay
		view.frame = CGRectMake(SCREEN_WIDTH - 50, 0, view.frame.size.width, view.frame.size.height);

		CGFloat scale = 0.1; // MIN(MAX(scale, 0.1), 0.98);
		view.transform = CGAffineTransformMakeScale(scale, scale);
		view.center = CGPointMake(SCREEN_WIDTH - (view.frame.size.width / 2), view.center.y);
	}

	view.tag = SwipeOverViewTag;
	[overlayWindow addSubview:view];

	[self updateClientSizes:YES];
}

- (void)closeCurrentView {
	if ([[overlayWindow currentView] isKindOfClass:[RAHostedAppView class]]) {
		((RAHostedAppView *)overlayWindow.currentView).shouldUseExternalKeyboard = NO;
		[((RAHostedAppView *)overlayWindow.currentView) unloadApp];
	}
	[[overlayWindow currentView] removeFromSuperview];
}

- (void)convertSwipeOverViewToSideBySide {
	if (!currentAppIdentifier || [[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive]) {
		[self stopUsingSwipeOver];
		return;
	}

	if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"MULTIPLEXER", @"Localizable") message:@"Sorry, SwipeOver's side-by-side mode is not currently compatible with landscape." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
		[alert show];
		return;
	}

	[[RAMessagingServer sharedInstance] setShouldUseExternalKeyboard:YES forApp:currentAppIdentifier completion:nil];

	if ([[overlayWindow currentView] isKindOfClass:[RAHostedAppView class]]) {
		((RAHostedAppView *)[overlayWindow currentView]).autosizesApp = YES;
	}
	[overlayWindow currentView].transform = CGAffineTransformIdentity;
	[overlayWindow removeOverlayFromUnderlyingApp];
	[overlayWindow currentView].frame = (CGRect) { { 10, 0 }, [overlayWindow currentView].frame.size };
	overlayWindow.frame = CGRectOffset(overlayWindow.frame, SCREEN_WIDTH / 2, 0);
	[self sizeViewForTranslation:CGPointZero state:UIGestureRecognizerStateEnded]; // force it
	[self updateClientSizes:YES];
}

- (void)detachViewAndCloseSwipeOver {
	SBApplication *app = ((RAHostedAppView *)overlayWindow.currentView).app;
	[self stopUsingSwipeOver];

	RADesktopWindow *desktop = [[%c(RADesktopManager) sharedInstance] currentDesktop];
	[desktop createAppWindowForSBApplication:app animated:YES];
}

- (void)updateClientSizes:(BOOL)reloadAppSelectorSizeNow {
	if (currentAppIdentifier && !overlayWindow.isHidingUnderlyingApp) {
		CGFloat underWidth = [overlayWindow isHidingUnderlyingApp] ? -1 : overlayWindow.frame.origin.x;
		[[RAMessagingServer sharedInstance] resizeApp:currentAppIdentifier toSize:CGSizeMake(underWidth, -1) completion:nil];
	}

	if (overlayWindow.isShowingAppSelector && reloadAppSelectorSizeNow) {
		[self showAppSelector];
	} else if (!overlayWindow.isHidingUnderlyingApp) { // Update swiped-over app in side-by-side mode. RAHostedAppView takes care of the app sizing if we resize the RAHostedAppView.
		overlayWindow.currentView.frame = CGRectMake(10, 0, SCREEN_WIDTH - overlayWindow.frame.origin.x - 10, overlayWindow.currentView.frame.size.height);
	}
}

- (void)sizeViewForTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state {
	static CGFloat lastX = -1;
	static CGFloat overlayOriginX = -1;
	UIView *targetView = [overlayWindow isHidingUnderlyingApp] ? [overlayWindow viewWithTag:SwipeOverViewTag] : overlayWindow;
	LogDebug(@"sizeViewForTranslation");

	if (start == 0) {
		start = targetView.center.x;
	}

	if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled || state == UIGestureRecognizerStateFailed) {
		lastX = -1;
		start = 0;
		overlayOriginX = -1;

		CGFloat scale = (SCREEN_WIDTH - targetView.frame.origin.x) / [overlayWindow currentView].bounds.size.width;
		if (scale <= 0.12 && (!CGPointEqualToPoint(translation, CGPointZero))) {
			[self stopUsingSwipeOver];
			return;
		}
	} else {
		//if (start + translation.x + (targetView.frame.size.width / 2) < UIScreen.mainScreen.bounds.size.width && [overlayWindow isHidingUnderlyingApp])
		//	return;
		//if (start + translation.x + targetView.frame.size.width - (targetView.frame.size.width / 2) < 0 && [overlayWindow isHidingUnderlyingApp] == NO)
		//	return;

		if (overlayWindow.isHidingUnderlyingApp) {
			if (![[overlayWindow currentView] isKindOfClass:[RAAppSelectorView class]]) {
				if (lastX == -1) {
					lastX = translation.x;
				}
				CGFloat newScale = (lastX - translation.x) / SCREEN_WIDTH;
				lastX = translation.x;

				newScale = newScale + sqrt(targetView.transform.a * targetView.transform.a + targetView.transform.c * targetView.transform.c);
				CGFloat scale = MIN(MAX(newScale, 0.1), UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? (UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height / targetView.bounds.size.height) - 0.02 : 0.98);

				//CGFloat height = UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height;
				//if (targetView.bounds.size.height * scale >= height)
				//	scale = scale - ((targetView.bounds.size.height * scale) - height);

				//NSLog(@"[ReachApp] %f %f", newScale, scale);

				targetView.transform = CGAffineTransformMakeScale(scale, scale);
				targetView.center = (CGPoint) { SCREEN_WIDTH - (targetView.frame.size.width / 2), overlayWindow.center.y };

				//CGFloat scale = (SCREEN_WIDTH - (start + translation.x)) / [overlayWindow currentView].bounds.size.width;
				//scale = MIN(MAX(scale, 0.1), 0.98);
				//targetView.transform = CGAffineTransformMakeScale(scale, scale);
				//targetView.center = (CGPoint) { SCREEN_WIDTH - (targetView.frame.size.width / 2), targetView.center.y };
			}
		} else {
			if (overlayOriginX == -1) {
				overlayOriginX = overlayWindow.frame.origin.x;
			}
			overlayWindow.frame = CGRectMake(overlayOriginX + translation.x, overlayWindow.frame.origin.y, SCREEN_WIDTH - (overlayOriginX + translation.x), overlayWindow.frame.size.height);
			//targetView.frame = CGRectMake(SCREEN_WIDTH - (start + translation.x), 0, SCREEN_WIDTH - (SCREEN_WIDTH - start + translation.x), targetView.frame.size.height);
			targetView.center = (CGPoint) { start + translation.x, targetView.center.y };
		}
	}
	[self updateClientSizes:state == UIGestureRecognizerStateEnded];
}
@end
