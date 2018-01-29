#import "headers.h"
#import "RAAppSelectorView.h"

@interface RASwipeOverOverlay : UIAutoRotatingWindow <UIGestureRecognizerDelegate, RAAppSelectorViewDelegate> {
	UIVisualEffectView *darkenerView;
}
@property (strong, readonly, nonatomic) UIView *grabberView;
@property (getter=isHidingUnderlyingApp, readonly, nonatomic) BOOL hidingUnderlyingApp;

- (void)showEnoughToDarkenUnderlyingApp;
- (void)removeOverlayFromUnderlyingApp;
- (void)removeOverlayFromUnderlyingAppImmediately;

- (BOOL)isShowingAppSelector;
- (void)showAppSelector;

- (UIView *)currentView;
@end
