#import "RASpringBoardKeyboardActivation.h"
#import "headers.h"
#import "RAMessaging.h"
#import "RAMessagingClient.h"
#import "RAKeyboardWindow.h"
#import "RARemoteKeyboardView.h"

extern BOOL overrideDisableForStatusBar;
RAKeyboardWindow *keyboardWindow;

@implementation RASpringBoardKeyboardActivation
+ (instancetype)sharedInstance {
  SHARED_INSTANCE2(RASpringBoardKeyboardActivation,
    [[RARunningAppsProvider sharedInstance] addTarget:self]
  );
}

- (void)showKeyboardForAppWithIdentifier:(NSString *)identifier {
  if (keyboardWindow) {
    [self hideKeyboard];
    //NSLog(@"[ReachApp] springboard cancelling - keyboardWindow exists");
    //return;
  }

  LogDebug(@"[ReachApp] showing kb window (%@)", identifier);
  keyboardWindow = [[RAKeyboardWindow alloc] init];
  overrideDisableForStatusBar = YES;
  [keyboardWindow setupForKeyboardAndShow:identifier];
  _currentIdentifier = identifier;

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    overrideDisableForStatusBar = NO;
  });
}

- (void)hideKeyboard {
  LogDebug(@"[ReachApp] remove kb window (%@)", _currentIdentifier);
  keyboardWindow.hidden = YES;
  [keyboardWindow removeKeyboard];
  keyboardWindow = nil;
  _currentIdentifier = nil;
}

- (void)appDidDie:(SBApplication *)app {
  if (![_currentIdentifier isEqualToString:app.bundleIdentifier]) {
    return;
  }
  [self hideKeyboard];
}

- (UIWindow *)keyboardWindow {
  return keyboardWindow;
}
@end
