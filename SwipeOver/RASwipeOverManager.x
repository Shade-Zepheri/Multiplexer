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
	CGFloat start;
	BOOL didWantOrientationEvents;
}

//@property (strong, nonatomic) UIView *fakeStatusBar; Ill figure that out later
@property (strong, nonatomic) RASwipeOverOverlay *overlayWindow;
@end

@implementation RASwipeOverManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE(RASwipeOverManager);
}

- (void)showAppSelector {
	[self.overlayWindow showAppSelector];
}

- (BOOL)isEdgeViewShowing {
	return self.overlayWindow.frame.origin.x < SCREEN_WIDTH;
}

- (void)startUsingSwipeOver {
	start = 0;
	_usingSwipeOver = YES;
	currentAppIdentifier = [UIApplication sharedApplication]._accessibilityFrontMostApplication.bundleIdentifier;

	[self createEdgeView];

	[RAOrientationLocker lockOrientation];
}

- (void)stopUsingSwipeOver {
	[self.overlayWindow removeOverlayFromUnderlyingAppImmediately];
	if (currentAppIdentifier) {
		[[RAMessagingServer sharedInstance] endResizingApp:currentAppIdentifier completion:nil];
		[[RAMessagingServer sharedInstance] setShouldUseExternalKeyboard:YES forApp:currentAppIdentifier completion:nil];
	}

	[RAOrientationLocker unlockOrientation];

	_usingSwipeOver = NO;
	currentAppIdentifier = nil;

	CGRect frame = self.overlayWindow.frame;
	CGPoint newCenter = self.overlayWindow.center;
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationUnknown:
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
		if ([[self.overlayWindow currentView] isKindOfClass:[RAHostedAppView class]]) {
			[((RAHostedAppView *)self.overlayWindow.currentView) viewWithTag:9903553].alpha = 0;
		}
		self.overlayWindow.center = newCenter;
	} completion:^(BOOL finished) {
		if (finished) {
			[self closeCurrentView];

			self.overlayWindow.hidden = YES;
			self.overlayWindow = nil;
		}
	}];
}

- (void)createEdgeView {
	self.overlayWindow = [[RASwipeOverOverlay alloc] initWithFrame:[UIScreen mainScreen].RA_interfaceOrientedBounds];
	[self.overlayWindow showEnoughToDarkenUnderlyingApp];
	[self.overlayWindow makeKeyAndVisible];
	[self.overlayWindow updateForOrientation:[UIApplication sharedApplication].statusBarOrientation];

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
	if (!self.overlayWindow.hidingUnderlyingApp) {
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
	detachGesture.delegate = self.overlayWindow;
	detachView.tag = 9903553;
	[view addSubview:detachView];

	if (!self.overlayWindow.hidingUnderlyingApp) { // side-by-side
		view.frame = CGRectMake(10, 0, view.frame.size.width, view.frame.size.height);
	} else { // overlay
		view.frame = CGRectMake(SCREEN_WIDTH - 50, 0, view.frame.size.width, view.frame.size.height);

		CGFloat scale = 0.1; // MIN(MAX(scale, 0.1), 0.98);
		view.transform = CGAffineTransformMakeScale(scale, scale);
		view.center = CGPointMake(SCREEN_WIDTH - (view.frame.size.width / 2), view.center.y);
	}

	view.tag = SwipeOverViewTag;
	[self.overlayWindow addSubview:view];

	[self updateClientSizes:YES];
}

- (void)closeCurrentView {
	if ([[self.overlayWindow currentView] isKindOfClass:[RAHostedAppView class]]) {
		((RAHostedAppView *)self.overlayWindow.currentView).shouldUseExternalKeyboard = NO;
		[((RAHostedAppView *)self.overlayWindow.currentView) unloadApp];
	}
	[[self.overlayWindow currentView] removeFromSuperview];
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

	if ([[self.overlayWindow currentView] isKindOfClass:[RAHostedAppView class]]) {
		((RAHostedAppView *)[self.overlayWindow currentView]).autosizesApp = YES;
	}
	[self.overlayWindow currentView].transform = CGAffineTransformIdentity;
	[self.overlayWindow removeOverlayFromUnderlyingApp];
	[self.overlayWindow currentView].frame = CGRectMake(10, 0, [self.overlayWindow currentView].frame.size.width, [self.overlayWindow currentView].frame.size.height);
	self.overlayWindow.frame = CGRectOffset(self.overlayWindow.frame, SCREEN_WIDTH / 2, 0);
	[self sizeViewForTranslation:CGPointZero state:UIGestureRecognizerStateEnded]; // force it
	[self updateClientSizes:YES];
}

- (void)detachViewAndCloseSwipeOver {
	SBApplication *app = ((RAHostedAppView *)self.overlayWindow.currentView).app;
	[self stopUsingSwipeOver];

	RADesktopWindow *desktop = [[%c(RADesktopManager) sharedInstance] currentDesktop];
	[desktop createAppWindowForSBApplication:app animated:YES];
}

- (void)updateClientSizes:(BOOL)reloadAppSelectorSizeNow {
	if (currentAppIdentifier && !self.overlayWindow.hidingUnderlyingApp) {
		CGFloat underWidth = self.overlayWindow.hidingUnderlyingApp ? -1 : self.overlayWindow.frame.origin.x;
		[[RAMessagingServer sharedInstance] resizeApp:currentAppIdentifier toSize:CGSizeMake(underWidth, -1) completion:nil];
	}

	if (self.overlayWindow.isShowingAppSelector && reloadAppSelectorSizeNow) {
		[self showAppSelector];
	} else if (!self.overlayWindow.hidingUnderlyingApp) { // Update swiped-over app in side-by-side mode. RAHostedAppView takes care of the app sizing if we resize the RAHostedAppView.
		self.overlayWindow.currentView.frame = CGRectMake(10, 0, SCREEN_WIDTH - self.overlayWindow.frame.origin.x - 10, self.overlayWindow.currentView.frame.size.height);
	}
}

- (void)sizeViewForTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state {
	static CGFloat lastX = -1;
	static CGFloat overlayOriginX = -1;
	UIView *targetView = self.overlayWindow.hidingUnderlyingApp ? [self.overlayWindow viewWithTag:SwipeOverViewTag] : self.overlayWindow;

	if (start == 0) {
		start = targetView.center.x;
	}

	if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled || state == UIGestureRecognizerStateFailed) {
		lastX = -1;
		start = 0;
		overlayOriginX = -1;

		CGFloat scale = (SCREEN_WIDTH - targetView.frame.origin.x) / [self.overlayWindow currentView].bounds.size.width;
		if (scale <= 0.12 && (!CGPointEqualToPoint(translation, CGPointZero))) {
			[self stopUsingSwipeOver];
			return;
		}
	} else {
		//if (start + translation.x + (targetView.frame.size.width / 2) < UIScreen.mainScreen.bounds.size.width && [self.overlayWindow isHidingUnderlyingApp])
		//	return;
		//if (start + translation.x + targetView.frame.size.width - (targetView.frame.size.width / 2) < 0 && [self.overlayWindow isHidingUnderlyingApp] == NO)
		//	return;

		if (self.overlayWindow.hidingUnderlyingApp) {
			if (![[self.overlayWindow currentView] isKindOfClass:[RAAppSelectorView class]]) {
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
				targetView.center = CGPointMake(SCREEN_WIDTH - (targetView.frame.size.width / 2), self.overlayWindow.center.y);

				//CGFloat scale = (SCREEN_WIDTH - (start + translation.x)) / [self.overlayWindow currentView].bounds.size.width;
				//scale = MIN(MAX(scale, 0.1), 0.98);
				//targetView.transform = CGAffineTransformMakeScale(scale, scale);
				//targetView.center = (CGPoint) { SCREEN_WIDTH - (targetView.frame.size.width / 2), targetView.center.y };
			}
		} else {
			if (overlayOriginX == -1) {
				overlayOriginX = self.overlayWindow.frame.origin.x;
			}
			self.overlayWindow.frame = CGRectMake(overlayOriginX + translation.x, self.overlayWindow.frame.origin.y, SCREEN_WIDTH - (overlayOriginX + translation.x), self.overlayWindow.frame.size.height);
			//targetView.frame = CGRectMake(SCREEN_WIDTH - (start + translation.x), 0, SCREEN_WIDTH - (SCREEN_WIDTH - start + translation.x), targetView.frame.size.height);
			targetView.center = CGPointMake(start + translation.x, targetView.center.y);
		}
	}
	[self updateClientSizes:state == UIGestureRecognizerStateEnded];
}
@end
