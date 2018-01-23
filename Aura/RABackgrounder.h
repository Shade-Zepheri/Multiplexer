#import "headers.h"

typedef NS_ENUM(NSInteger, RABackgroundMode) {
  RABackgroundModeNative,
  RABackgroundModeForcedForeground,
  RABackgroundModeForceNone,
  RABackgroundModeSuspendImmediately,
  RABackgroundModeUnlimitedBackgroundingTime,
};

typedef NS_OPTIONS(NSInteger, RAIconIndicatorViewInfo) {
  RAIconIndicatorViewInfoNone                    = 0,
  RAIconIndicatorViewInfoNative                  = 1 << 0,
  RAIconIndicatorViewInfoForced                  = 1 << 1,
  RAIconIndicatorViewInfoSuspendImmediately      = 1 << 2,
  RAIconIndicatorViewInfoUnkillable              = 1 << 3,
  RAIconIndicatorViewInfoForceDeath              = 1 << 4,
  RAIconIndicatorViewInfoUnlimitedBackgroundTime = 1 << 5,
  RAIconIndicatorViewInfoTemporarilyInhibit      = 1 << 6,
  RAIconIndicatorViewInfoInhibit                 = 1 << 7,
  RAIconIndicatorViewInfoUninhibit               = 1 << 8,
};

NSString *FriendlyNameForBackgroundMode(RABackgroundMode mode);

@interface RABackgrounder : NSObject
@property (strong, nonatomic) NSMutableDictionary *temporaryOverrides;
@property (strong, nonatomic) NSMutableDictionary *temporaryShouldPop;

+ (instancetype)sharedInstance;

- (RABackgroundMode)globalBackgroundMode;

- (BOOL)shouldAutoLaunchApplication:(NSString *)identifier;
- (BOOL)shouldAutoRelaunchApplication:(NSString *)identifier;

- (BOOL)shouldKeepInForeground:(NSString *)identifier;
- (BOOL)shouldSuspendImmediately:(NSString *)identifier;

- (BOOL)killProcessOnExit:(NSString *)identifier;
- (BOOL)shouldRemoveFromSwitcherWhenKilledOnExit:(NSString *)identifier;
- (BOOL)preventKillingOfIdentifier:(NSString *)identifier;
- (RABackgroundMode)backgroundModeForIdentifier:(NSString *)identifier;
- (BOOL)hasUnlimitedBackgroundTime:(NSString *)identifier;

- (void)temporarilyApplyBackgroundingMode:(RABackgroundMode)mode forApplication:(SBApplication *)app andCloseForegroundApp:(BOOL)close;
- (void)queueRemoveTemporaryOverrideForIdentifier:(NSString *)identifier;
- (void)removeTemporaryOverrideForIdentifier:(NSString *)identifier;

- (NSInteger)application:(NSString *)identifier overrideBackgroundMode:(NSString *)mode;

- (RAIconIndicatorViewInfo)allAggregatedIndicatorInfoForIdentifier:(NSString *)identifier;
- (void)updateIconIndicatorForIdentifier:(NSString *)identifier withInfo:(RAIconIndicatorViewInfo)info;
- (BOOL)shouldShowIndicatorForIdentifier:(NSString *)identifier;
- (BOOL)shouldShowStatusBarIconForIdentifier:(NSString *)identifier;
@end
