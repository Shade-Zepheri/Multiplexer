#import "headers.h"
#import "RABackgrounder.h"
#import <FrontBoard/FBApplicationInfo.h>
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

%hook FBApplicationInfo
- (BOOL)supportsBackgroundMode:(NSString *)mode {
	NSInteger override = [[RABackgrounder sharedInstance] application:self.bundleIdentifier overrideBackgroundMode:mode];
	if (override == -1) {
		return %orig;
	}

	return override;
}
%end

%hook BKSProcessAssertion
- (instancetype)initWithPID:(NSInteger)pid flags:(NSUInteger)flags reason:(NSUInteger)reason name:(NSString *)name withHandler:(id)handler {
	if (reason == BKSProcessAssertionReasonViewServices || [name isEqualToString:@"Called by iOS6_iCleaner, from unknown method"] || [name isEqualToString:@"Called by Filza_main, from -[AppDelegate applicationDidEnterBackground:]"] || [name isEqualToString:@"QRC"]) {
		//Whitelist share menu, iCleaner, Filza and QRC
		return %orig;
	}

	NSString *identifier = [NSBundle mainBundle].bundleIdentifier;

	if (!identifier) {
		goto ORIGINAL;
	}

	//LogDebug(@"BKSProcessAssertion initWithPID:'%zd' flags:'%tu' reason:'%tu' name:'%@' withHandler:'%@' process identifier:'%@'", pid, flags, reason, name, handler, identifier);

	if ([[RABackgrounder sharedInstance] shouldSuspendImmediately:identifier]) {
	  if ((reason >= BKSProcessAssertionReasonAudio && reason <= BKSProcessAssertionReasonVOiP)) { // In most cases reason == 4 (finish task)
	    return nil;
	  }
	}

ORIGINAL:
	return %orig(pid, flags, reason, name, handler);
}
%end
