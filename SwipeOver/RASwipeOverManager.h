#import "headers.h"

@interface RASwipeOverManager : NSObject {
	NSString *currentAppIdentifier;
}
@property (getter=isUsingSwipeOver, nonatomic, readonly) BOOL usingSwipeOver;

+ (instancetype)sharedInstance;

- (void)startUsingSwipeOver;
- (void)stopUsingSwipeOver;

- (void)createEdgeView;

- (void)showApp:(NSString *)identifier; // if identifier is nil it will use the app switcher data
- (void)closeCurrentView; // App or selector
- (void)showAppSelector; // No widget chooser, not enough horizontal space. TODO: make it work anyway

- (BOOL)isEdgeViewShowing;
- (void)convertSwipeOverViewToSideBySide;

- (void)sizeViewForTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state;
@end

static NSInteger const SwipeOverViewTag = 996;
