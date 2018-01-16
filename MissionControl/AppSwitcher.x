#import "headers.h"
#import "RAGestureManager.h"
#import "RAMissionControlManager.h"
#import "RAMissionControlWindow.h"
#import "RASettings.h"
#import "RASnapshotProvider.h"
#import "RADesktopManager.h"
#import "Multiplexer.h"

BOOL allowMissionControlActivationFromSwitcher = YES;
BOOL statusBarVisibility;
BOOL willShowMissionControl = NO;
BOOL toggleOrActivate = NO;

%hook SpringBoard
- (void)_performDeferredLaunchWork {
	%orig;

	[[Multiplexer sharedInstance] registerExtension:@"com.shade.missioncontrol" forMultiplexerVersion:@"1.0.0"];
}
%end

%hook SBUIController
- (BOOL)clickedMenuButton {
	if ([RAMissionControlManager sharedInstance].showingMissionControl) {
		[[RAMissionControlManager sharedInstance] hideMissionControl:YES];
		return YES;
	}

	return %orig;
}

- (BOOL)handleHomeButtonSinglePressUp {
	if ([RAMissionControlManager sharedInstance].showingMissionControl) {
		[[RAMissionControlManager sharedInstance] hideMissionControl:YES];
		return YES;
	}

	return %orig;
}

- (BOOL)isAppSwitcherShowing {
	return %orig || [RAMissionControlManager sharedInstance].showingMissionControl;
}
%end

%hook SBNotificationCenterController
- (void)beginPresentationWithTouchLocation:(CGPoint)location presentationBegunHandler:(id)handler {
	if ([[RASettings sharedInstance] missionControlEnabled] && [[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && CGRectContainsPoint([[[[%c(SBMainSwitcherViewController) sharedInstance] valueForKey:@"_contentView"] contentView] viewWithTag:999].frame, location)) {
		return;
	}

	%orig;
}

- (void)_beginDismissalWithTouchLocation:(CGPoint)location {
	[RAMissionControlManager sharedInstance].inhibitDismissalGesture = YES;
	%orig;
}
%end

%hook SBAppSwitcherController
- (void)switcherScroller:(id)scroller itemTapped:(SBDisplayLayout *)layout {
	SBDisplayItem *item = [layout displayItems][0];
	NSString *identifier = item.displayIdentifier;

	[[%c(RADesktopManager) sharedInstance] removeAppWithIdentifier:identifier animated:NO forceImmediateUnload:YES];

	%orig;
}
%end

%hook SBSwitcherContainerView
- (void)layoutSubviews {
	%orig;

	UIView *view = self.contentView;

	if (![view viewWithTag:999] && ([[RASettings sharedInstance] missionControlEnabled] && ![[RASettings sharedInstance] replaceAppSwitcherWithMC])) {
		CGFloat width = 50, height = 30;
		if (IS_IPAD) {
			width = 60;
		  height = 40;
		}

		if (%c(SBControlCenterGrabberView)) {
			SBControlCenterGrabberView *grabber = [[%c(SBControlCenterGrabberView) alloc] initWithFrame:CGRectMake(0, 0, width, height)];
			grabber.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, 20/2);
			grabber.backgroundColor = [UIColor clearColor];
			//grabber.chevronView.vibrantSettings = [%c(_SBFVibrantSettings) vibrantSettingsWithReferenceColor:UIColor.whiteColor referenceContrast:0.5 legibilitySettings:nil];

			_UIBackdropViewSettings *blurSettings = [_UIBackdropViewSettings settingsForStyle:2060 graphicsQuality:100];
			_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithFrame:grabber.frame autosizesToFitSuperview:YES settings:blurSettings];;
			[grabber insertSubview:blurView atIndex:0];

			[grabber.chevronView setState:1 animated:NO];

			grabber.layer.cornerRadius = 5;

			//[grabber.chevronView setState:1 animated:YES];
			grabber.tag = 999;
			[view addSubview:grabber];

		} else {
			UIView *grabber = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
			grabber.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, 20/2);

			_UIBackdropViewSettings *blurSettings = [_UIBackdropViewSettings settingsForStyle:2060 graphicsQuality:100];
			_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithFrame:grabber.frame autosizesToFitSuperview:YES settings:blurSettings];;
			blurView._blurRadius = 30;
			[blurView _setCornerRadius:6];
			[blurView _applyCornerRadiusToSubviews];
			[grabber addSubview:blurView];

			SBUIChevronView *chevronView = [[%c(SBUIChevronView) alloc] initWithColor:[UIColor blackColor]];
			chevronView.frame = CGRectMake((width - 36) / 2, (height - 14) / 2, 36, 14);
			[chevronView setState:1 animated:NO];
			chevronView.alpha = 0.6499;
			[grabber addSubview:chevronView];

			grabber.layer.cornerRadius = 6;

			grabber.tag = 999;
			[view addSubview:grabber];

		}
		[[RAGestureManager sharedInstance] addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol> *)self forEdge:UIRectEdgeTop identifier:@"com.efrederickson.reachapp.appswitchergrabber"];
	} else {
		((UIView *)[view viewWithTag:999]).center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, 20/2);
	}
}

%new - (BOOL)RAGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity {
	return allowMissionControlActivationFromSwitcher && [[RASettings sharedInstance] missionControlEnabled] && [[%c(SBUIController) sharedInstance] isAppSwitcherShowing];
}

%new - (RAGestureCallbackResult)RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge {
	if ([%c(SBUIController) respondsToSelector:@selector(_showNotificationsGestureFailed)]) {
		[[%c(SBUIController) sharedInstance] performSelector:@selector(_showNotificationsGestureFailed)];
		[[%c(SBUIController) sharedInstance] performSelector:@selector(_showNotificationsGestureCancelled)];
	} else {
		[[%c(SBNotificationCenterController) sharedInstance] performSelector:@selector(_showNotificationCenterGestureFailed)];
		[[%c(SBNotificationCenterController) sharedInstance] performSelector:@selector(_showNotificationCenterGestureCancelled)];
	}

	static CGFloat origY = -1;
	static UIView *fakeView;
	UIView *view = self.contentView;

	if (!fakeView) {
		UIImage *snapshot = [[RASnapshotProvider sharedInstance] storedSnapshotOfMissionControl];

		if (snapshot) {
			fakeView = [[UIImageView alloc] initWithFrame:view.frame];
			((UIImageView *)fakeView).image = snapshot;
			[view addSubview:fakeView];
		} else {
			fakeView = [[UIView alloc] initWithFrame:view.frame];

			CGFloat width = [UIScreen mainScreen].RA_interfaceOrientedBounds.size.width / 4.5714;
			CGFloat height = [UIScreen mainScreen].RA_interfaceOrientedBounds.size.height / 4.36;

			_UIBackdropViewSettings *blurSettings = [_UIBackdropViewSettings settingsForStyle:1 graphicsQuality:10];
			_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithFrame:fakeView.frame autosizesToFitSuperview:YES settings:blurSettings];;
			[fakeView addSubview:blurView];

			UILabel *desktopLabel, *windowedLabel, *otherLabel;
			UIScrollView *desktopScrollView, *windowedAppScrollView, *otherRunningAppsScrollView;

			CGFloat x = 15;
			CGFloat y = 20;

			desktopLabel = [[UILabel alloc] initWithFrame:CGRectMake(9.37, y, fakeView.frame.size.width - 20, 25)];
			desktopLabel.font = [UIFont fontWithName:@"SFUIText-Medium" size:14];
			desktopLabel.textColor = UIColor.whiteColor;
			desktopLabel.text = @"Desktops";
			[fakeView addSubview:desktopLabel];

			y = y + desktopLabel.frame.size.height;

			desktopScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, fakeView.frame.size.width, height * 1.15)];
			desktopScrollView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.3];

			[fakeView addSubview:desktopScrollView];

			UIButton *newDesktopButton = [[UIButton alloc] init];
			newDesktopButton.frame = CGRectMake(x, 20, width, height);
			newDesktopButton.backgroundColor = [UIColor darkGrayColor];
			[newDesktopButton setTitle:@"+" forState:UIControlStateNormal];
			newDesktopButton.titleLabel.font = [UIFont systemFontOfSize:36];
			[desktopScrollView addSubview:newDesktopButton];

			x = 15;
			y = desktopScrollView.frame.origin.y + desktopScrollView.frame.size.height + 7;

			windowedLabel = [[UILabel alloc] initWithFrame:CGRectMake(9.37, y, fakeView.frame.size.width - 20, 25)];
			windowedLabel.font = [UIFont fontWithName:@"SFUIText-Medium" size:14];
			windowedLabel.textColor = UIColor.whiteColor;
			windowedLabel.text = @"On This Desktop";
			[fakeView addSubview:windowedLabel];

			windowedAppScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + windowedLabel.frame.size.height, fakeView.frame.size.width, height * 1.15)];
			windowedAppScrollView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.3];

			[fakeView addSubview:windowedAppScrollView];

			x = 15;
			y = windowedAppScrollView.frame.origin.y + windowedAppScrollView.frame.size.height + 7;

			otherLabel = [[UILabel alloc] initWithFrame:CGRectMake(9.37, y, fakeView.frame.size.width - 20, 25)];
			otherLabel.font = [UIFont fontWithName:@"SFUIText-Medium" size:14];
			otherLabel.textColor = UIColor.whiteColor;
			otherLabel.text = @"Running Elsewhere";
			[fakeView addSubview:otherLabel];

			otherRunningAppsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + otherLabel.frame.size.height, fakeView.frame.size.width, height * 1.15)];
			otherRunningAppsScrollView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.3];

			[fakeView addSubview:otherRunningAppsScrollView];

			[view addSubview:fakeView];
		}
	}

	if (origY == -1) {
		CGRect f = fakeView.frame;
		f.origin.y = -f.size.height;
		fakeView.frame = f;
		origY = fakeView.center.y;
	}

	if (state == UIGestureRecognizerStateChanged) {
		fakeView.center = CGPointMake(fakeView.center.x, origY + location.y);
	}

	if (state == UIGestureRecognizerStateEnded) {
		//NSLog(@"[ReachApp] %@ + %@ = %@ > %@", NSStringFromCGPoint(fakeView.frame.origin), NSStringFromCGPoint(velocity), @(fakeView.frame.origin.y + velocity.y), @(-([UIScreen mainScreen].bounds.size.height / 2)));

		if (fakeView.frame.origin.y + velocity.y > -([UIScreen mainScreen].RA_interfaceOrientedBounds.size.height / 2)) {
			willShowMissionControl = YES;
			CGFloat distance = [UIScreen mainScreen].RA_interfaceOrientedBounds.size.height - (fakeView.frame.origin.y + fakeView.frame.size.height);
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			//NSLog(@"[ReachApp] dist %f, dur %f", distance, duration);

			[UIView animateWithDuration:duration animations:^{
				fakeView.frame = [UIScreen mainScreen].RA_interfaceOrientedBounds;
			} completion:^(BOOL _) {
				//((UIWindow*)[[%c(SBUIController) sharedInstance] switcherWindow]).alpha = 0;
				if ([%c(SBUIController) respondsToSelector:@selector(dismissSwitcherAnimated:)]) {
					[[%c(SBUIController) sharedInstance] dismissSwitcherAnimated:NO];
				} else {
					[UIView performWithoutAnimation:^{
						[[%c(SBMainSwitcherViewController) sharedInstance] dismissSwitcherNoninteractively];
					}];
				}
				[[RAMissionControlManager sharedInstance] showMissionControl:NO];
				[fakeView removeFromSuperview];
				fakeView = nil;
				[UIApplication sharedApplication].statusBarHidden = statusBarVisibility;
				// avoid status bar hiding
				//dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				//	((UIWindow*)[[%c(SBUIController) sharedInstance] switcherWindow]).alpha = 1;
				//});
			}];
		} else {
			CGFloat distance = fakeView.frame.size.height + fakeView.frame.origin.y /* origin.y is less than 0 so the + is actually a - operation */;
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			//NSLog(@"[ReachApp] dist %f, dur %f", distance, duration);

			[UIView animateWithDuration:duration animations:^{
				fakeView.frame = CGRectMake(fakeView.frame.origin.x, -fakeView.frame.size.height, fakeView.frame.size.width, fakeView.frame.size.height);
			} completion:^(BOOL _) {
				[fakeView removeFromSuperview];
				fakeView = nil;
			}];
		}
	}

	return RAGestureCallbackResultSuccess;
}
%end

%hook SBMainSwitcherViewController
- (void)viewDidAppear:(BOOL)animated {
	statusBarVisibility = [UIApplication sharedApplication].statusBarHidden;
	willShowMissionControl = NO;

	if ([[RASettings sharedInstance] replaceAppSwitcherWithMC] && [[RASettings sharedInstance] missionControlEnabled]) {
		if (![RAMissionControlManager sharedInstance].showingMissionControl) {
			[[RAMissionControlManager sharedInstance] showMissionControl:YES];
	  } else {
			[[RAMissionControlManager sharedInstance] hideMissionControl:YES];
		}
	} else if ([RAMissionControlManager sharedInstance].showingMissionControl) {
		[[RAMissionControlManager sharedInstance] hideMissionControl:YES];
	}

	%orig;

	[[%c(RADesktopManager) sharedInstance] performSelectorOnMainThread:@selector(hideDesktop) withObject:nil waitUntilDone:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (!willShowMissionControl) {
		[[%c(RADesktopManager) sharedInstance] reshowDesktop];
		//[[[%c(RADesktopManager) sharedInstance] currentDesktop] loadApps];
	}
	%orig;
}

//Because I cant think of a better solution
- (BOOL)toggleSwitcherNoninteractively {
	if (![self isVisible]) {
		return [self activateSwitcherNoninteractively];
	} else {
		return [self dismissSwitcherNoninteractively];
	}
}

- (BOOL)activateSwitcherNoninteractively {
	if ([[RASettings sharedInstance] replaceAppSwitcherWithMC] && [[RASettings sharedInstance] missionControlEnabled]) {
		if (![RAMissionControlManager sharedInstance].showingMissionControl) {
			[[RAMissionControlManager sharedInstance] showMissionControl:YES];
		} else {
			[[RAMissionControlManager sharedInstance] hideMissionControl:YES];
		}

		return YES;
	} else if ([RAMissionControlManager sharedInstance].showingMissionControl) {
		[[RAMissionControlManager sharedInstance] hideMissionControl:YES];
	}

	return %orig;
}
%end
