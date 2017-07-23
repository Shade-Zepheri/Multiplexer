#import "headers.h"
#import "RABackgrounder.h"
#import "RARunningAppsProvider.h"

NSMutableDictionary *processAssertions = [NSMutableDictionary dictionary];
BKSProcessAssertion *keepAlive$temp;

%hook FBUIApplicationWorkspaceScene
- (void)host:(FBScene *)scene didUpdateSettings:(FBSSceneSettings *)settings withDiff:(id)diff transitionContext:(id)context completion:(void (^)(BOOL))completion {
  if ([[RABackgrounder sharedInstance] hasUnlimitedBackgroundTime:scene.identifier] && settings.backgrounded && ![processAssertions objectForKey:scene.identifier]) {
    ProcessAssertionFlags flags = BKSProcessAssertionFlagPreventSuspend | BKSProcessAssertionFlagAllowIdleSleep | BKSProcessAssertionFlagPreventThrottleDownCPU | BKSProcessAssertionFlagWantsForegroundResourcePriority;
    keepAlive$temp = [[%c(BKSProcessAssertion) alloc] initWithBundleIdentifier:scene.identifier flags:flags reason:BKSProcessAssertionReasonBackgroundUI name:@"reachapp" withHandler:^{
      LogInfo(@"ReachApp: %@ kept alive: %@", scene.identifier, keepAlive$temp.valid ? @"TRUE" : @"FALSE");
      if (keepAlive$temp.valid) {
        processAssertions[scene.identifier] = keepAlive$temp;
      }
    }];
  }
  %orig(scene, settings, diff, context, completion);
}
%end

@interface RAUnlimitedBackgroundingAppWatcher : NSObject <RARunningAppsProviderDelegate>
+ (void)load;
@end

static RAUnlimitedBackgroundingAppWatcher *sharedInstance$RAUnlimitedBackgroundingAppWatcher;

@implementation RAUnlimitedBackgroundingAppWatcher
+ (void)load {
  IF_NOT_SPRINGBOARD {
    return;
  }

  sharedInstance$RAUnlimitedBackgroundingAppWatcher = [[RAUnlimitedBackgroundingAppWatcher alloc] init];
  [[RARunningAppsProvider sharedInstance] addTarget:sharedInstance$RAUnlimitedBackgroundingAppWatcher];
}

- (void)appDidDie:(SBApplication *)app {
  if (![processAssertions objectForKey:app.bundleIdentifier]) {
    return;
  }

  [processAssertions[app.bundleIdentifier] invalidate];
  [processAssertions removeObjectForKey:app.bundleIdentifier];
}
@end
