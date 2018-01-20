#import "RAHostManager.h"
#import "RACompatibilitySystem.h"

@implementation RAHostManager
+ (UIView *)systemHostViewForApplication:(SBApplication *)app {
	if (!app) {
		return nil;
	}

	return [[app mainScene].contextHostManager valueForKey:@"_hostView"];
}

+ (UIView *)enabledHostViewForApplication:(SBApplication *)app {
	if (!app) {
		return nil;
	}

	FBScene *scene = [app mainScene];
	FBSMutableSceneSettings *settings = scene.mutableSettings;
	if (!settings) {
		return nil;
	}

	settings.backgrounded = NO;
	[scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

	FBWindowContextHostManager *contextHostManager = scene.contextHostManager;
	[contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
	return [contextHostManager hostViewForRequester:@"reachapp" appearanceStyle:2];
}

+ (NSObject *)hostManagerForApp:(SBApplication *)app {
	if (!app) {
		return nil;
	}

	FBScene *scene = [app mainScene];
	return (NSObject *)scene.contextHostManager;
}
@end
