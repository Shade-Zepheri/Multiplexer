#import "headers.h"
#import "RASettings.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"

extern BOOL launchNextOpenIntoWindow;
BOOL override = NO;
BOOL allowOpenApp = NO;

%hook SBIconController
- (void)iconWasTapped:(__unsafe_unretained SBApplicationIcon*)icon {
	if ([RASettings.sharedInstance windowedMultitaskingEnabled] && [RASettings.sharedInstance launchIntoWindows] && icon.application) {
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:icon.application animated:YES];
		override = YES;
	}
	%orig;
}

- (void)_launchIcon:(unsafe_id)icon {
	if (!override) {
		%orig;
	} else {
		override = NO;
	}
}
%end

%hook SBUIController
- (void)activateApplicationAnimated:(__unsafe_unretained SBApplication*)application {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([RASettings.sharedInstance windowedMultitaskingEnabled] && [RASettings.sharedInstance launchIntoWindows] && !allowOpenApp) {
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:application animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[RADesktopManager.sharedInstance removeAppWithIdentifier:application.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}

- (void)activateApplication:(__unsafe_unretained SBApplication*)application {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([RASettings.sharedInstance windowedMultitaskingEnabled] && [RASettings.sharedInstance launchIntoWindows] && !allowOpenApp) {
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:application animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[RADesktopManager.sharedInstance removeAppWithIdentifier:application.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}
%end
