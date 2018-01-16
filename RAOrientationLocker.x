#import "RAOrientationLocker.h"

@implementation RAOrientationLocker
+ (void)lockOrientation {
	[[%c(SBMainSwitcherGestureCoordinator) sharedInstance] _lockOrientation];
}


+ (void)unlockOrientation {
	[[%c(SBMainSwitcherGestureCoordinator) sharedInstance] _releaseOrientationLock];
}
@end
