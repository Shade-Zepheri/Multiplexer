#import "headers.h"

@class RAHostedAppView;

@interface RANCViewController : UIViewController <SBApplicationHosting> {
    SBAppViewController *_appViewController;
}

+ (instancetype)defaultViewController;

- (void)forceReloadAppLikelyBecauseTheSettingChanged;

@end
