#import "headers.h"

@class RAHostedAppView;

@interface RANCViewController : SBNCColumnViewController
+ (instancetype)sharedViewController;

- (RAHostedAppView *)hostedApp;
- (void)forceReloadAppLikelyBecauseTheSettingChanged;
@end
