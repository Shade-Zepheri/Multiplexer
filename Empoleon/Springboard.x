#import "headers.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "Multiplexer.h"

%hook SpringBoard
- (void)_performDeferredLaunchWork {
  %orig;
  [RADesktopManager sharedInstance]; // load desktop (and previous windows!)
  [[Multiplexer sharedInstance] registerExtension:@"com.shade.empoleon" forMultiplexerVersion:@"1.0.0"];

  // No applications show in the mission control until they have been launched by the user.
  // This prevents always-running apps like Mail or Pebble from perpetually showing in Mission Control.
  //[[%c(RAMissionControlManager) sharedInstance] setInhibitedApplications:[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers]];
}
%end

%hook SBToAppsWorkspaceTransaction
- (void)_willBegin {
  @autoreleasepool {
    NSArray *apps = self.toApplications;
    for (SBApplication *app in apps) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [[RADesktopManager sharedInstance] removeAppWithIdentifier:app.bundleIdentifier animated:NO forceImmediateUnload:YES];
      });
    }
  }
  %orig;
}
%end

%ctor {
  IF_NOT_SPRINGBOARD {
    return;
  }

  %init;
}
