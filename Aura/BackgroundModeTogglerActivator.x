#import <libactivator/libactivator.h>
#import "RAAlertItem.h"
#import "RABackgrounder.h"
#import "RASettings.h"

@interface RAActivatorBackgrounderToggleModeListener : NSObject <LAListener>
@end

static RAActivatorBackgrounderToggleModeListener *sharedInstance$RAActivatorBackgrounderToggleModeListener;

@implementation RAActivatorBackgrounderToggleModeListener

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    SBApplication *app = [UIApplication sharedApplication]._accessibilityFrontMostApplication;

    if (!app) {
        return;
    }

    BOOL dismissApp = [[RASettings sharedInstance] exitAppAfterUsingActivatorAction];

    NSString *friendlyCurrentBackgroundMode = FriendlyNameForBackgroundMode((RABackgroundMode)[[RABackgrounder sharedInstance] backgroundModeForIdentifier:app.bundleIdentifier]);
    NSString *message = [NSString stringWithFormat:LOCALIZE(@"BACKGROUNDER_POPUP_SWITCHER_TEXT", @"Localizable"), app.displayName, friendlyCurrentBackgroundMode];
    RAAlertItem *alertItem = [%c(RAAlertItem) alertItemWithTitle:LOCALIZE(@"MULTIPLEXER", @"Localizable") andMessage:message];

    UIAlertAction *forceForeground = [UIAlertAction actionWithTitle:LOCALIZE(@"FORCE_FOREGROUND", @"Aura") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[RABackgrounder sharedInstance] temporarilyApplyBackgroundingMode:RABackgroundModeForcedForeground forApplication:app andCloseForegroundApp:dismissApp];
        [alertItem deactivateForButton];
    }];

    UIAlertAction *native = [UIAlertAction actionWithTitle:LOCALIZE(@"NATIVE", @"Aura") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[RABackgrounder sharedInstance] temporarilyApplyBackgroundingMode:RABackgroundModeNative forApplication:app andCloseForegroundApp:dismissApp];
        [alertItem deactivateForButton];
    }];

    UIAlertAction *suspendImmediately = [UIAlertAction actionWithTitle:LOCALIZE(@"SUSPEND_IMMEDIATELY", @"Aura") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[RABackgrounder sharedInstance] temporarilyApplyBackgroundingMode:RABackgroundModeSuspendImmediately forApplication:app andCloseForegroundApp:dismissApp];
        [alertItem deactivateForButton];
    }];

    UIAlertAction *killOnExit = [UIAlertAction actionWithTitle:LOCALIZE(@"KILL_ON_EXIT", @"Aura") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[RABackgrounder sharedInstance] temporarilyApplyBackgroundingMode:RABackgroundModeForceNone forApplication:app andCloseForegroundApp:dismissApp];
        [alertItem deactivateForButton];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:LOCALIZE(@"CANCEL", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alertItem deactivateForButton];
    }];
    alertItem.alertActions = @[forceForeground, native, suspendImmediately, killOnExit, cancel];

    [alertItem.class activateAlertItem:alertItem];
}

@end

%ctor {
  IF_NOT_SPRINGBOARD {
    return;
  }

  sharedInstance$RAActivatorBackgrounderToggleModeListener = [[RAActivatorBackgrounderToggleModeListener alloc] init];
  [[%c(LAActivator) sharedInstance] registerListener:sharedInstance$RAActivatorBackgrounderToggleModeListener forName:@"com.efrederickson.reachapp.backgrounder.togglemode"];
}
