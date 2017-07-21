#import "headers.h"
#import "RABackgrounder.h"
#import "RARunningAppsProvider.h"

NSMutableDictionary *processAssertions = [NSMutableDictionary dictionary];
BKSProcessAssertion *keepAlive$temp;

%hook FBUIApplicationWorkspaceScene
- (void)host:(FBScene *)scene didUpdateSettings:(FBSSceneSettings *)settings withDiff:(id)diff transitionContext:(id)context completion:(void (^)(BOOL))completion {
  if ([[RABackgrounder sharedInstance] hasUnlimitedBackgroundTime:scene.identifier] && settings.backgrounded && ![processAssertions objectForKey:scene.identifier]) {
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:scene.identifier];

    ProcessAssertionFlags flags = BKSProcessAssertionFlagPreventSuspend | BKSProcessAssertionFlagAllowIdleSleep | BKSProcessAssertionFlagPreventThrottleDownCPU | BKSProcessAssertionFlagWantsForegroundResourcePriority;
    keepAlive$temp = [[%c(BKSProcessAssertion) alloc] initWithPID:app.pid flags:flags reason:BKSProcessAssertionReasonBackgroundUI name:@"reachapp" withHandler:^{
      LogInfo(@"ReachApp: %d kept alive: %@", app.pid, keepAlive$temp.valid ? @"TRUE" : @"FALSE");
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
  [[%c(RARunningAppsProvider) sharedInstance] addTarget:sharedInstance$RAUnlimitedBackgroundingAppWatcher];
}

- (void)appDidDie:(__unsafe_unretained SBApplication *)app {
  if (![processAssertions objectForKey:app.bundleIdentifier]) {
    return;
  }

  [processAssertions[app.bundleIdentifier] invalidate];
  [processAssertions removeObjectForKey:app.bundleIdentifier];
}
@end
