#import "RASystemGesturesInhibitor.h"
#import "headers.h"

static BOOL _gesturesInhibited = NO;

@implementation RASystemGesturesInhibitor : NSObject

+ (void)setGesturesInhibited:(BOOL)value {
	_gesturesInhibited = value;
	[%c(SBSystemGestureManager) mainDisplayManager].systemGesturesDisabledForAccessibility = value;
}

+ (BOOL)gesturesInhibited {
	return _gesturesInhibited;
}

@end
