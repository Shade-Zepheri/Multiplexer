#import "RAControlCenterInhibitor.h"
#import "headers.h"
#import <UIKit/UIKit.h>

static BOOL _gesturesInhibited = NO;

@implementation RAControlCenterInhibitor : NSObject
+ (void)setGesturesInhibited:(BOOL)value {
	_gesturesInhibited = value;
	[%c(SBSystemGestureManager) mainDisplayManager].systemGesturesDisabledForAccessibility = value;
}

+ (BOOL)gesturesInhibited {
	return _gesturesInhibited;
}
@end
