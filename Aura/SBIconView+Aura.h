#import "headers.h"

@interface SBIconView (Aura)
@property (strong, nonatomic) SBIconBadgeView *_ra_badgeView;

// Cuz _frameForAccessoryView needs an accessoryView to work
- (CGRect)_ra_frameForAccessoryView:(SBIconBadgeView *)accessoryView;

// Added methods
- (void)_ra_createCustomBadgeViewIfNecessary;
- (void)_ra_updateCustomBadgeWithInfo:(RAIconIndicatorViewInfo)info;
- (void)_ra_updateCustomBadge;

@end