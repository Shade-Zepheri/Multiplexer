#import "headers.h"
#import "RACompatibilitySystem.h"
#import "RASettings.h"
#import "RASnapshotProvider.h"
#import "Asphaleia.h"

BOOL overrideDisableForStatusBar = NO;

%hook SBToAppsWorkspaceTransaction
// On iOS 8.3 and above, on the iPad, if a FBWindowContextWhatever creates a hosting context / enabled hosting, all the other hosted windows stop.
// This fixes that.
- (void)_didComplete {
  %orig;

  //TODO revisit this
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
// Not in iOS 11
- (void)didActivateForScene:(FBScene *)scene transactionID:(NSUInteger)transactionID {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [[RASnapshotProvider sharedInstance] forceReloadOfSnapshotForIdentifier:self.bundleIdentifier];
  });

  %orig;
}

%end

static void respring_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  if (%c(SBSRelaunchAction)) {
    SBSRelaunchAction *restartAction = [%c(SBSRelaunchAction) actionWithReason:@"RestartRenderServer" options:SBSRelaunchActionOptionsFadeToBlack targetURL:nil];
    [[FBSSystemService sharedService] sendActions:[NSSet setWithObject:restartAction] withResult:nil];
  } else {
    [(SpringBoard *)[UIApplication sharedApplication] _relaunchSpringBoardNow];
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
