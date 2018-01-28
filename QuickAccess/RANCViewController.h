#import "headers.h"

@class RAHostedAppView;

@interface RANCViewController : UIViewController <SBApplicationHosting> {
    SBAppViewController *_appViewController;
}

+ (instancetype)defaultViewController;

- (CGSize)contentSizeForContainerSize:(CGSize)containerSize;
- (void)forceReloadAppLikelyBecauseTheSettingChanged;

@end
