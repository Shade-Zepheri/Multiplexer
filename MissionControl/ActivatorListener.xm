#import <libactivator/libactivator.h>
#import "RAMissionControlManager.h"
#import "RASettings.h"

@interface RAActivatorListener : NSObject <LAListener>
@end

static RAActivatorListener *sharedInstance;

@implementation RAActivatorListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	if ([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
		return;
	} else if ([[%c(RASettings) sharedInstance] missionControlEnabled]) {
	  [RAMissionControlManager.sharedInstance toggleMissionControl:YES];
		if ([%c(SBUIController) respondsToSelector:@selector(_appSwitcherController)]) {
			[[[%c(SBUIController) sharedInstance] _appSwitcherController] forceDismissAnimated:NO];
		} else {
			[[%c(SBMainSwitcherViewController) sharedInstance] dismissSwitcherNoninteractively];
		}
	}
  [event setHandled:YES];
}
@end

%ctor
{
    if (IN_SPRINGBOARD)
    {
        sharedInstance = [[RAActivatorListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance forName:@"com.efrederickson.reachapp.missioncontrol.activatorlistener"];
    }
}
