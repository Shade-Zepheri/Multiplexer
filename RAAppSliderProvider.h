#import "headers.h"

@class RAHostedAppView;

@interface RAAppSliderProvider : NSObject
@property (strong, nonatomic) NSArray *availableIdentifiers;
@property (nonatomic) NSInteger currentIndex;

- (BOOL)canGoLeft;
- (BOOL)canGoRight;

- (RAHostedAppView *)viewToTheLeft;
- (RAHostedAppView *)viewToTheRight;
- (RAHostedAppView *)viewAtCurrentIndex;

- (void)goToTheLeft;
- (void)goToTheRight;
@end
