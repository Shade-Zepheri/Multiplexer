#import "RAHostManager.h"
#import "RACompatibilitySystem.h"

@implementation RAHostManager
+ (UIView *)systemHostViewForApplication:(SBApplication *)app {
	if (!app) {
		return nil;
	}
	if ([app respondsToSelector:@selector(mainScene)]) { // iOS 8
		return [[app mainScene].contextHostManager valueForKey:@"_hostView"];
	} else if ([app respondsToSelector:@selector(mainScreenContextHostManager)]) {
		return [[app mainScreenContextHostManager] valueForKey:@"_hostView"];
	}
	[RACompatibilitySystem showWarning:@"Unable to find valid method for accessing system context host views"];
	return nil;
}

+ (UIView *)enabledHostViewForApplication:(SBApplication *)app {
	if (!app) {
		return nil;
	}

	if ([app respondsToSelector:@selector(mainScene)]) {
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

	[RACompatibilitySystem showWarning:@"Unable to find valid method for accessing context host views"];
	return nil;
}

+ (NSObject *)hostManagerForApp:(SBApplication *)app {
	if (!app) {
		return nil;
	}

	if ([app respondsToSelector:@selector(mainScene)]) {
	  FBScene *scene = [app mainScene];
	  return (NSObject *)scene.contextHostManager;
	}

	[RACompatibilitySystem showWarning:@"Unable to find valid method for accessing context host view managers"];
	return nil;
}
@end
