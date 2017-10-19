#import "headers.h"
#import "RAHostedAppView.h"
#import "RAGestureManager.h"

@class RAAppSliderProvider;

@interface RAAppSliderProviderView : UIView<RAGestureCallbackProtocol> {
	RAHostedAppView *currentView;
}
@property (strong, nonatomic) RAAppSliderProvider *swipeProvider;
@property (nonatomic) BOOL isSwipeable;

- (CGRect)clientFrame;
- (NSString *)currentBundleIdentifier;

- (void)goToTheLeft;
- (void)goToTheRight;

- (void)load;
- (void)unload;
- (void)updateCurrentView;
@end
