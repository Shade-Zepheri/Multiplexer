#import "RAAppKiller.h"
#import "RARunningAppsStateProvider.h"

@interface RAAppKiller () {
	NSMutableDictionary *completionDictionary;
}
@end

@implementation RAAppKiller : NSObject
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RAAppKiller,
		[sharedInstance initialize];
	);
}

+ (void)killAppWithIdentifier:(NSString *)identifier {
	return [RAAppKiller killAppWithIdentifier:identifier completion:nil];
}

+ (void)killAppWithIdentifier:(NSString *)identifier completion:(void(^)())handler {
	return [RAAppKiller checkAppDead:identifier withTries:0 andCompletion:handler];
}

+ (void)killAppWithSBApplication:(SBApplication *)app {
	return [RAAppKiller killAppWithSBApplication:app completion:nil];
}

+ (void)killAppWithSBApplication:(SBApplication *)app completion:(void(^)())handler {
	return [RAAppKiller killAppWithIdentifier:app.bundleIdentifier completion:handler];
}

+ (void)checkAppDead:(NSString *)identifier withTries:(NSInteger)tries andCompletion:(void(^)())handler {
	/*
	BOOL isDeadOrMaxed = (app.pid == 0 || app.isRunning == NO) && tries < 5;
	if (isDeadOrMaxed)
	{
		if (handler)
		{
			handler();
		}
	}
	else
	{
		if (tries == 0)
		{
			// Try nicely
			FBApplicationProcess *process = [[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:app.bundleIdentifier];
			[process killForReason:1 andReport:NO withDescription:@"PSY SLAYED" completion:nil];
		}
		/*else if (tries == 1)
		{
			BKSTerminateApplicationForReasonAndReportWithDescription(app.bundleIdentifier, 5, 1, @"PSY SLAYED");
		}
		else if (tries == 2)
		{
			kill(app.pid, SIGTERM);
		}
		else
		{
			// Attempt force
			kill(app.pid, SIGKILL);
		}* /
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[RAAppKiller checkAppDead:app withTries:tries + 1 andCompletion:handler];
		});
	}
	*/

	[[RAAppKiller sharedInstance]->completionDictionary setObject:[handler copy] forKey:identifier];
	BKSTerminateApplicationForReasonAndReportWithDescription(identifier, 5, true, @"Multiplexer requested this process to be slayed.");
}

- (void)initialize {
	completionDictionary = [NSMutableDictionary dictionary];
	[[RARunningAppsStateProvider defaultStateProvider] addObserver:self];
}

- (void)applicationDidExit:(NSString *)bundleIdentifier {
	if (!completionDictionary || ![completionDictionary objectForKey:bundleIdentifier]) {
		return;
	}

	dispatch_block_t block = completionDictionary[bundleIdentifier];
	block();
	[completionDictionary removeObjectForKey:bundleIdentifier];
}
@end