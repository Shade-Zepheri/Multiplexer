#import "RAOrientationLocker.h"

static BOOL _orientationLocked = NO;

@implementation RAOrientationLocker

+ (void)setOrientationLocked:(BOOL)locked {
	_orientationLocked = locked;
	[[%c(SBOrientationLockManager) sharedInstance] setLockOverrideEnabled:locked forReason:@"Multiplexer"];
}

+ (BOOL)orientationLocked {
	return _orientationLocked;
}

@end
