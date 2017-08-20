#import "RAControlCenterInhibitor.h"
#import "headers.h"
#import <UIKit/UIKit.h>

BOOL overrideCC = NO;

@implementation RAControlCenterInhibitor : NSObject
+ (void)setInhibited:(BOOL)value {
	overrideCC = value;

	if (%c(SBSystemGestureManager)) {
		[[%c(SBSystemGestureManager) mainDisplayManager] setSystemGesturesDisabledForAccessibility:value];
	}
}

+ (BOOL)isInhibited {
	return overrideCC;
}
@end

%hook SBUIController
- (void)_showControlCenterGestureBeganWithLocation:(CGPoint)point {
	if (overrideCC) {
		return;
	}

	%orig;
}

- (void)handleShowControlCenterSystemGesture:(id)gesture {
	if (overrideCC) {
		return;
	}

	%orig;
}
%end
