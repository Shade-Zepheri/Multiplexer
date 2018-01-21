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
    [[RARunningAppsStateProvider defaultStateProvider] addObserver:self]
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
  overrideDisableForStatusBar = NO;
  _currentIdentifier = identifier;
}

- (void)hideKeyboard {
  LogDebug(@"[ReachApp] remove kb window (%@)", _currentIdentifier);
  keyboardWindow.hidden = YES;
  [keyboardWindow removeKeyboard];
  keyboardWindow = nil;
  _currentIdentifier = nil;
}

- (void)applicationDidExit:(NSString *)bundleIdentifier {
  if (![_currentIdentifier isEqualToString:bundleIdentifier]) {
    return;
  }

  [self hideKeyboard];
}

- (UIWindow *)keyboardWindow {
  return keyboardWindow;
}
@end