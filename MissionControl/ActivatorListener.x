#import <libactivator/libactivator.h>
#import "RAMissionControlManager.h"
#import "RASettings.h"

@interface RAActivatorListener : NSObject <LAListener>
@end

static RAActivatorListener *sharedInstance;

@implementation RAActivatorListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	if ([[%c(SBLockScreenManager) sharedInstance] isUILocked] || ![[RASettings sharedInstance] missionControlEnabled]) {
		return;
	}

	[[RAMissionControlManager sharedInstance] toggleMissionControl:YES];
	if ([%c(SBUIController) respondsToSelector:@selector(_appSwitcherController)]) {
		[[[%c(SBUIController) sharedInstance] _appSwitcherController] forceDismissAnimated:NO];
	} else {
		[UIView performWithoutAnimation:^{
			[[%c(SBMainSwitcherViewController) sharedInstance] dismissSwitcherNoninteractively];
		}];
	}
	event.handled = YES;
}
@end

%ctor {
	IF_NOT_SPRINGBOARD {
		return;
	}

	sharedInstance = [[RAActivatorListener alloc] init];
	[[%c(LAActivator) sharedInstance] registerListener:sharedInstance forName:@"com.efrederickson.reachapp.missioncontrol.activatorlistener"];
}
