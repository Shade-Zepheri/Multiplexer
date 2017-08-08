#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>
#import "RACompatibilitySystem.h"
#import "headers.h"
#import "RAWidgetSectionManager.h"
#import "RASettings.h"
#import "RASwipeOverManager.h"
#import "RAMissionControlManager.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "Asphaleia.h"
#import "RASnapshotProvider.h"

BOOL overrideDisableForStatusBar = NO;

%hook SBUIController
- (BOOL)clickedMenuButton {
	if ([[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver]) {
		[[%c(RASwipeOverManager) sharedInstance] stopUsingSwipeOver];
		return YES;
	}

	if ([[RASettings sharedInstance] homeButtonClosesReachability] && [RASettings isReachAppInstalled] && [GET_SBWORKSPACE isUsingReachApp] && ((SBReachabilityManager *)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive) {
		overrideDisableForStatusBar = NO;
		[[%c(SBReachabilityManager) sharedInstance] _handleReachabilityDeactivated];
		return YES;
	}

	if ([[%c(RAMissionControlManager) sharedInstance] isShowingMissionControl]) {
		[[%c(RAMissionControlManager) sharedInstance] hideMissionControl:YES];
		return YES;
	}

	return %orig;
}

- (BOOL)handleHomeButtonSinglePressUp {
	if ([[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver]) {
		[[%c(RASwipeOverManager) sharedInstance] stopUsingSwipeOver];
		return YES;
	}

	if ([[RASettings sharedInstance] homeButtonClosesReachability] && [RASettings isReachAppInstalled] && [GET_SBWORKSPACE isUsingReachApp] && ((SBReachabilityManager *)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive) {
		overrideDisableForStatusBar = NO;
		[[%c(SBReachabilityManager) sharedInstance] _handleReachabilityDeactivated];
		return YES;
	}

	if ([[%c(RAMissionControlManager) sharedInstance] isShowingMissionControl]) {
		[[%c(RAMissionControlManager) sharedInstance] hideMissionControl:YES];
		return YES;
	}

	return %orig;
}

/*- (_Bool)handleMenuDoubleTap
{
    if ([[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver])
    {
        [[%c(RASwipeOverManager) sharedInstance] stopUsingSwipeOver];
    }

    //if (RAMissionControlManager.sharedInstance.isShowingMissionControl)
    //{
    //    [RAMissionControlManager.sharedInstance hideMissionControl:YES];
    //}

    return %orig;
}*/

// This should help fix the problems where closing an app with Tage or the iPad Gesture would cause the app to suspend(?) and lock up the device.
// Seems like unneeded on iOS 9+
- (void)_suspendGestureBegan {
  %orig;
  [[UIApplication sharedApplication]._accessibilityFrontMostApplication clearDeactivationSettings];
}
%end

%hook SpringBoard
- (void)_performDeferredLaunchWork {
  %orig;
  [%c(RADesktopManager) sharedInstance]; // load desktop (and previous windows!)

  // No applications show in the mission control until they have been launched by the user.
  // This prevents always-running apps like Mail or Pebble from perpetually showing in Mission Control.
  //[[%c(RAMissionControlManager) sharedInstance] setInhibitedApplications:[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers]];
}
%end

%hook SBApplicationController
%new - (SBApplication *)RA_applicationWithBundleIdentifier:(NSString *)bundleIdentifier {
  if ([self respondsToSelector:@selector(applicationWithBundleIdentifier:)]) {
		return [self applicationWithBundleIdentifier:bundleIdentifier];
	} else if ([self respondsToSelector:@selector(applicationWithDisplayIdentifier:)]) {
		return [self applicationWithDisplayIdentifier:bundleIdentifier];
	}

  [RACompatibilitySystem showWarning:@"Unable to find valid -[SBApplicationController applicationWithBundleIdentifier:] replacement"];
  return nil;
}
%end

%hook SBToAppsWorkspaceTransaction
- (void)_willBegin {
	@autoreleasepool {
	  NSArray *apps = self.toApplications;
	  for (SBApplication *app in apps) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [[%c(RADesktopManager) sharedInstance] removeAppWithIdentifier:app.bundleIdentifier animated:NO forceImmediateUnload:YES];
      });
	  }
	}
	%orig;
}

// On iOS 8.3 and above, on the iPad, if a FBWindowContextWhatever creates a hosting context / enabled hosting, all the other hosted windows stop.
// This fixes that.
- (void)_didComplete {
  %orig;

  // can't hurt to check all devices - especially if it changes/has changed to include phones.
  // however this was presumably done in preparation for the iOS 9 multitasking
	if (IS_IPAD && !IS_IOS_OR_NEWER(iOS_10_0)) {
		[RAHostedAppView iPad_iOS83_fixHosting];
	}
}
%end

/*
%hook SBRootFolderView
- (_Bool)_hasMinusPages
{
    return RADesktopManager.sharedInstance.currentDesktop.hostedWindows.count > 0 ? YES : %orig;
}
- (unsigned long long)_minusPageCount
{
    return RADesktopManager.sharedInstance.currentDesktop.hostedWindows.count > 0 ? 1 : %orig;
}
%end
*/

%hook SpringBoard
- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation duration:(CGFloat)duration {
	%orig;
	[[RASnapshotProvider sharedInstance] forceReloadEverything];
}

- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation duration:(CGFloat)duration logMessage:(NSString *)message {
	%orig;
	[[RASnapshotProvider sharedInstance] forceReloadEverything];
}
%end

%hook SBApplication
- (void)didActivateWithTransactionID:(NSUInteger)transactionID {
	dispatch_async(dispatch_get_main_queue(), ^{
	  [[RASnapshotProvider sharedInstance] forceReloadOfSnapshotForIdentifier:self.bundleIdentifier];
	});

	%orig;
}

- (void)didActivateForScene:(FBScene *)scene transactionID:(NSUInteger)transactionID {
	dispatch_async(dispatch_get_main_queue(), ^{
		[[RASnapshotProvider sharedInstance] forceReloadOfSnapshotForIdentifier:self.bundleIdentifier];
	});

	%orig;
}
%end

%hook SBLockScreenManager
- (void)_postLockCompletedNotification:(BOOL)value {
	%orig;

	if (value && [[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver]) {
		[[%c(RASwipeOverManager) sharedInstance] stopUsingSwipeOver];
	}
}
%end

%hook UIScreen
%new - (CGRect)RA_interfaceOrientedBounds {
	if ([self respondsToSelector:@selector(_interfaceOrientedBounds)]) {
		return [self _interfaceOrientedBounds];
	}
	return [self bounds];
}
%end

static void respring_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	if (IS_IOS_OR_NEWER(iOS_9_3)) {
		SBSRelaunchAction *restartAction = [%c(SBSRelaunchAction) actionWithReason:@"RestartRenderServer" options:SBSRelaunchOptionsFadeToBlack targetURL:nil];
		[[%c(FBSSystemService) sharedService] sendActions:[NSSet setWithObject:restartAction] withResult:nil];
	} else {
		[[UIApplication sharedApplication] _relaunchSpringBoardNow];
	}
}

static inline void reset_settings_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[RASettings sharedInstance] resetSettings];
}

%ctor {
	IF_NOT_SPRINGBOARD {
		return;
	}
	%init;
	LOAD_ASPHALEIA;

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &respring_notification, CFSTR("com.efrederickson.reachapp.respring"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reset_settings_notification, CFSTR("com.efrederickson.reachapp.resetSettings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
