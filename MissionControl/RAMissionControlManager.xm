#import "headers.h"
#import "RAMissionControlWindow.h"
#import "RAMissionControlManager.h"
#import "RAMissionControlPreviewView.h"
#import "RADesktopWindow.h"
#import "RADesktopManager.h"
#import "RAWindowBar.h"
#import "RAHostedAppView.h"
#import "RASnapshotProvider.h"
#import "RAAppKiller.h"
#import "RAGestureManager.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RAHostManager.h"
#import "RARunningAppsProvider.h"
#import "RAControlCenterInhibitor.h"
#import "RASettings.h"
#import "RAOrientationLocker.h"

@interface RAMissionControlManager () {
	SBApplication *lastOpenedApp;
	NSMutableArray *appsWithoutWindows;

	UIStatusBar *statusBar;

	__block UIView *originalAppView;
	__block CGRect originalAppFrame;
	BOOL hasMoved;
	BOOL didStoreSnapshot;
}
@end

CGRect swappedForOrientation(CGRect input) {
	if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
		CGFloat x = input.origin.x;
		input.origin.x = input.origin.y;
		input.origin.y = x;
	} else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
		CGFloat x = input.origin.x;
		input.origin.x = fabs(input.origin.y) + [UIScreen mainScreen].bounds.size.width;
		input.origin.y = x;
	}

	return input;
}

CGRect swappedForOrientation2(CGRect in) {
	if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
		CGFloat x = in.origin.x;
		in.origin.x = in.origin.y;
		in.origin.y = x;
	} else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
		CGFloat x = in.origin.x;
		in.origin.x = -in.size.width;
		in.origin.y = x;
	}

	return in;
}

@implementation RAMissionControlManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RAMissionControlManager,
		sharedInstance->originalAppView = nil;
		sharedInstance.inhibitDismissalGesture = NO;
		sharedInstance->hasMoved = NO;
	);
}

- (void)showMissionControl:(BOOL)animated {
	if (![NSThread isMainThread]) {
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self showMissionControl:animated];
		});
		return;
	}

	_isShowingMissionControl = YES;

	SBApplication *app = [UIApplication sharedApplication]._accessibilityFrontMostApplication;
	if (app) {
		lastOpenedApp = app;
	}

	[self createWindow];

	if (animated) {
		window.frame = CGRectMake(0, -window.frame.size.height, window.frame.size.width, window.frame.size.height);
	}
		//window.alpha = 0;

	[window makeKeyAndVisible];

	if (lastOpenedApp && lastOpenedApp.isRunning) {
		originalAppView = [RAHostManager systemHostViewForApplication:lastOpenedApp].superview;
		originalAppFrame = originalAppView.frame;
	}

	if (animated) {
		//[UIView animateWithDuration:0.5 animations:^{ window.alpha = 1; }];
		[UIView animateWithDuration:0.5 animations:^{
			window.frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);

			if (originalAppView) {
				originalAppView.frame = CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height);
			}
		} completion:nil];
	} else if (originalAppView) {  // dismiss even if not animating open
		originalAppView.frame = CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height);
	}

	[window updateForOrientation:[UIApplication sharedApplication].statusBarOrientation];
	[[RAGestureManager sharedInstance] addGestureRecognizerWithTarget:self forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.missioncontrol.dismissgesture" priority:RAGesturePriorityHigh];
	[[RAGestureManager sharedInstance] ignoreSwipesBeginningInRect:[UIScreen mainScreen].bounds forIdentifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture"];
	[[RARunningAppsProvider sharedInstance] addTarget:window];
	[RAOrientationLocker lockOrientation];
	if (!IS_IOS_OR_NEWER(iOS_10_0)) { //Not required on 10.x, not sure about other versions
		[[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"RAMissionControlManager"];
	}
	self.inhibitDismissalGesture = NO;
	[RAControlCenterInhibitor setInhibited:YES];

	if ([[%c(SBControlCenterController) sharedInstance] isVisible]) {
		[[%c(SBControlCenterController) sharedInstance] dismissAnimated:YES];
	}

	didStoreSnapshot = NO;
}

- (void)createWindow {
	if (window) {
		if (originalAppView) {
			originalAppView.frame = originalAppFrame;
		}
		window.hidden = YES;
		window = nil;
	}

	window = [[RAMissionControlWindow alloc] initWithFrame:[UIScreen mainScreen].RA_interfaceOrientedBounds];
	window.manager = self;
	//[window _rotateWindowToOrientation:[UIApplication sharedApplication].statusBarOrientation updateStatusBar:YES duration:1 skipCallbacks:NO];

	//_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithStyle:1];
	_UIBackdropViewSettings *blurSettings = [_UIBackdropViewSettings settingsForStyle:THEMED(missionControlBlurStyle) graphicsQuality:10]; // speed++ hopefully
	_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithFrame:window.frame autosizesToFitSuperview:YES settings:blurSettings];
	[window addSubview:blurView];

	int statusBarStyle = 0x12F; //Normal notification center style
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	statusBar = [[UIStatusBar alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].statusBar.bounds.size.width, [UIStatusBar heightForStyle:statusBarStyle orientation:orientation])];
	[statusBar requestStyle:statusBarStyle];
	statusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[window addSubview:statusBar];
	[statusBar setOrientation:orientation];

	// DESKTOPS
	[self reloadDesktopSection];

	// APPS WITH PANES
	[self reloadWindowedAppsSection];

	// APPS WITHOUT PANES
	[self reloadOtherAppsSection];
}

- (void)reloadDesktopSection {
	[window reloadDesktopSection];
}

- (void)reloadWindowedAppsSection {
	[window reloadWindowedAppsSection:[[RARunningAppsProvider sharedInstance] runningApplications]];
}

- (void)reloadOtherAppsSection {
	[window reloadOtherAppsSection];
}

- (void)hideMissionControl:(BOOL)animated {
	if (!didStoreSnapshot) {
		[[RASnapshotProvider sharedInstance] storeSnapshotOfMissionControl:window];
	}
	[[RARunningAppsProvider sharedInstance] removeTarget:window];

	void (^destructor)() = ^{
		originalAppView = nil;
		window.hidden = YES;
		window = nil;

		// This goes here to prevent the wallpaper from appearing black when dismissing
		//once again not needed on 10.x but not sure of older versions
		if (!IS_IOS_OR_NEWER(iOS_10_0)) {
			[[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"RAMissionControlManager"];
		}
	};

	if (animated) {
		[UIView animateWithDuration:0.5 animations:^{
			window.frame = swappedForOrientation(CGRectMake(0, -window.frame.size.height, window.frame.size.width, window.frame.size.height));

			if (originalAppView) {
				originalAppView.frame = originalAppFrame;
			}
		} completion:^(BOOL _) {
			destructor();
		}];
	} else {
		if (originalAppView) {
			originalAppView.frame = originalAppFrame;
		}
		destructor();
	}

	_isShowingMissionControl = NO;
	[[%c(RADesktopManager) sharedInstance] reshowDesktop];
	[[[%c(RADesktopManager) sharedInstance] currentDesktop] loadApps];
	[[RAGestureManager sharedInstance] removeGestureWithIdentifier:@"com.efrederickson.reachapp.missioncontrol.dismissgesture"];
	[[RAGestureManager sharedInstance] stopIgnoringSwipesForIdentifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture"];
	[RAOrientationLocker unlockOrientation];
	[RAControlCenterInhibitor setInhibited:NO];

	//if (lastOpenedApp && lastOpenedApp.isRunning && [UIApplication sharedApplication]._accessibilityFrontMostApplication != lastOpenedApp)
	//{
	//	if ([[%c(RADesktopManager) sharedInstance] isAppOpened:lastOpenedApp.bundleIdentifier] == NO)
	//	{
	//		[[%c(SBUIController) sharedInstance] activateApplicationAnimated:lastOpenedApp];
	//	}
	//}
	lastOpenedApp = nil; // Fix it opening the same app later if on the Homescreen
}

- (void)toggleMissionControl:(BOOL)animated {
	if (!self.isShowingMissionControl) {
		[self showMissionControl:animated];
	} else {
		[self hideMissionControl:animated];
	}
}

- (BOOL)RAGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity {
	return self.isShowingMissionControl && !self.inhibitDismissalGesture;
}

- (RAGestureCallbackResult)RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge {
	static CGPoint initialCenter;
	static CGRect initialAppFrame;

	if (state == UIGestureRecognizerStateEnded) {
		hasMoved = NO;
		[RAControlCenterInhibitor setInhibited:NO];

		BOOL dismiss = NO;
		switch ([UIApplication sharedApplication].statusBarOrientation) {
			case UIInterfaceOrientationPortrait:
				dismiss = window.frame.origin.y + window.frame.size.height + velocity.y < [UIScreen mainScreen].RA_interfaceOrientedBounds.size.height / 2;
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				dismiss = window.frame.origin.y + window.frame.size.height - velocity.y > [UIScreen mainScreen].RA_interfaceOrientedBounds.size.height / 2;
				break;
			case UIInterfaceOrientationLandscapeLeft:
				dismiss = window.frame.origin.x + window.frame.size.width < [UIScreen mainScreen].RA_interfaceOrientedBounds.size.width / 2.0;
				break;
			case UIInterfaceOrientationLandscapeRight:
				dismiss = window.frame.origin.x + velocity.y > [UIScreen mainScreen].bounds.size.width / 2.0;
				break;
		}

		if (dismiss) {
			// Close
			CGFloat distance = [UIScreen mainScreen].RA_interfaceOrientedBounds.size.height - (window.frame.origin.y + window.frame.size.height);
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			[UIView animateWithDuration:duration animations:^{
				CGRect frame = window.frame;
				switch ([UIApplication sharedApplication].statusBarOrientation) {
					case UIInterfaceOrientationPortrait:
						window.center = CGPointMake(window.center.x, -initialCenter.y);
						break;
					case UIInterfaceOrientationPortraitUpsideDown:
						window.center = CGPointMake(window.center.x, [UIScreen mainScreen].bounds.size.height + initialCenter.y);
						break;
					case UIInterfaceOrientationLandscapeLeft:
						frame.origin.x = -[UIScreen mainScreen].bounds.size.width;
						window.frame = frame;
						break;
					case UIInterfaceOrientationLandscapeRight:
						frame.origin.x = [UIScreen mainScreen].bounds.size.width;
						window.frame = frame;
						break;
				}

				if (originalAppView) {
					originalAppView.frame = originalAppFrame;
				}
			} completion:^(BOOL _) {
				[self hideMissionControl:NO];
			}];
		} else {
			CGFloat distance = window.center.y + window.frame.origin.y /* origin.y is less than 0 so the + is actually a - operation */;
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			[UIView animateWithDuration:duration animations:^{
				window.center = initialCenter;
				if (originalAppView) {
					originalAppView.frame = CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height);
				}
			}];
		}
	} else if (state == UIGestureRecognizerStateBegan) {
		//[[%c(RASnapshotProvider) sharedInstance] storeSnapshotOfMissionControl:window];
		didStoreSnapshot = YES;
		hasMoved = YES;
		[RAControlCenterInhibitor setInhibited:YES];
		initialCenter = window.center;
		if (originalAppView) {
			initialAppFrame = initialAppFrame;
		}
	} else {
		CGRect frame = window.frame;
		switch ([UIApplication sharedApplication].statusBarOrientation) {
			case UIInterfaceOrientationPortrait:
				window.center = CGPointMake(window.center.x, location.y - initialCenter.y);
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				window.center = CGPointMake(window.center.x, initialCenter.y + [UIScreen mainScreen].bounds.size.height - location.y);
				break;
			case UIInterfaceOrientationLandscapeLeft:
				frame.origin.x = -[UIScreen mainScreen].bounds.size.height + location.y;
				window.frame = frame;
				break;
			case UIInterfaceOrientationLandscapeRight:
				frame.origin.x = [UIScreen mainScreen].bounds.size.height - location.y;
				window.frame = frame;
				break;
		}

		if (originalAppView) {
			originalAppView.frame = CGRectMake(originalAppView.frame.origin.x, [UIScreen mainScreen].RA_interfaceOrientedBounds.size.height - ([UIScreen mainScreen].RA_interfaceOrientedBounds.size.height - location.y), originalAppFrame.size.width, originalAppFrame.size.height);
		}
	}
	return RAGestureCallbackResultSuccess;
}

- (RAMissionControlWindow *)missionControlWindow {
	return window;
}

- (void)setInhibitDismissalGesture:(BOOL)value {
	_inhibitDismissalGesture = value;
	if (value && hasMoved) {
		[self RAGestureCallback_handle:UIGestureRecognizerStateEnded withPoint:CGPointZero velocity:CGPointZero forEdge:UIRectEdgeBottom];
	}
}
@end

%hook SBLockStateAggregator
- (void)_updateLockState {
	%orig;

	if ([self hasAnyLockState] && [RAMissionControlManager sharedInstance].isShowingMissionControl) {
		[[RAMissionControlManager sharedInstance] hideMissionControl:NO];
	}
}
%end
