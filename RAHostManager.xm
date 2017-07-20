#import "RAHostManager.h"
#import "RACompatibilitySystem.h"

@implementation RAHostManager
+ (UIView*)systemHostViewForApplication:(SBApplication*)app {
	if (!app) {
		return nil;
	}
	if ([app respondsToSelector:@selector(mainScene)]) { // iOS 8
		return MSHookIvar<UIView*>([app mainScene].contextHostManager, "_hostView");
	} else if ([app respondsToSelector:@selector(mainScreenContextHostManager)]) {
		return MSHookIvar<UIView*>([app mainScreenContextHostManager], "_hostView");
	}
	[RACompatibilitySystem showWarning:@"Unable to find valid method for accessing system context host views"];
	return nil;
}

+ (UIView*)enabledHostViewForApplication:(SBApplication*)app {
	if (!app) {
		return nil;
	}

	if ([app respondsToSelector:@selector(mainScene)]) {
		FBScene *scene = [app mainScene];
		FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
		if (!settings) {
			return nil;
		}

		[[%c(FBSSystemService) sharedService] openApplication:app.bundleIdentifier options:@{ FBSOpenApplicationOptionKeyActivateSuspended : @YES } withResult:^{
			settings.backgrounded = NO;
			[scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
		}];

		FBWindowContextHostManager *contextHostManager = scene.contextHostManager;
		[contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
		return [contextHostManager hostViewForRequester:@"reachapp" enableAndOrderFront:YES];
	}

	[RACompatibilitySystem showWarning:@"Unable to find valid method for accessing context host views"];
	return nil;
}

+ (NSObject*)hostManagerForApp:(SBApplication*)app {
	if (!app) {
		return nil;
	}

	if ([app respondsToSelector:@selector(mainScene)]) {
	  FBScene *scene = [app mainScene];
	  return (NSObject*)scene.contextHostManager;
	}

	[RACompatibilitySystem showWarning:@"Unable to find valid method for accessing context host view managers"];
	return nil;
}
@end
