#import "RAHostManager.h"
#import "RACompatibilitySystem.h"

@implementation RAHostManager
+ (FBSceneLayerHostContainerView *)systemHostViewForApplication:(SBApplication *)app {
	if (!app) {
		return nil;
	}

	return [app.mainScene.hostManager valueForKey:@"_hostView"];
}

+ (FBSceneHostWrapperView *)enabledHostViewForApplication:(SBApplication *)app {
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

	FBSceneHostManager *hostManager = scene.hostManager;
	[hostManager enableHostingForRequester:@"reachapp" orderFront:YES];
	return [hostManager hostViewForRequester:@"reachapp" appearanceStyle:2];
}

+ (FBSceneHostManager *)hostManagerForApp:(SBApplication *)app {
	if (!app) {
		return nil;
	}

	FBScene *scene = app.mainScene;
  // Because FBWindowContextHostManager is gone on iOS 11 and its been FBSceneHostManager since iOS 9
  return scene.hostManager;
}
@end
