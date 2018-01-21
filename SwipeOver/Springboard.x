#import "headers.h"
#import "RASwipeOverManager.h"
#import "Multiplexer.h"

%hook SBUIController
- (BOOL)clickedMenuButton {
  if ([RASwipeOverManager sharedInstance].usingSwipeOver) {
    [[RASwipeOverManager sharedInstance] stopUsingSwipeOver];
    return YES;
  }

  return %orig;
}

- (BOOL)handleHomeButtonSinglePressUp {
  if ([RASwipeOverManager sharedInstance].usingSwipeOver) {
    [[RASwipeOverManager sharedInstance] stopUsingSwipeOver];
    return YES;
  }

  return %orig;
}
%end

%hook SBLockScreenManager
- (void)_postLockCompletedNotification:(BOOL)value {
  %orig;

  if (value && [RASwipeOverManager sharedInstance].usingSwipeOver) {
    [[RASwipeOverManager sharedInstance] stopUsingSwipeOver];
  }
}
%end

%hook SpringBoard
- (void)_performDeferredLaunchWork {
  %orig;

  [[Multiplexer sharedInstance] registerExtension:@"com.shade.swipeover" forMultiplexerVersion:@"1.0.0"];
}
%end

%ctor {
  IF_NOT_SPRINGBOARD {
    return;
  }

  %init;
}