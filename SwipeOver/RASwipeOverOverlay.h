#import "headers.h"
#import "RAAppSelectorView.h"

@interface RASwipeOverOverlay : UIAutoRotatingWindow <UIGestureRecognizerDelegate, RAAppSelectorViewDelegate> {
	UIVisualEffectView *darkenerView;
}
@property (strong, nonatomic) UIView *grabberView;
@property (getter=isHidingUnderlyingApp, nonatomic, readonly) BOOL hidingUnderlyingApp;

- (void)showEnoughToDarkenUnderlyingApp;
- (void)removeOverlayFromUnderlyingApp;
- (void)removeOverlayFromUnderlyingAppImmediately;

- (BOOL)isShowingAppSelector;
- (void)showAppSelector;

- (UIView *)currentView;
@end
