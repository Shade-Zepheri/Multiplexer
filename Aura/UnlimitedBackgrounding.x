#import "headers.h"
#import "RABackgrounder.h"
#import "RARunningAppsStateProvider.h"

NSMutableDictionary *processAssertions;
BKSProcessAssertion *keepAlive$temp;

%hook FBUIApplicationWorkspaceScene
- (void)host:(FBScene *)scene didUpdateSettings:(FBSSceneSettings *)settings withDiff:(id)diff transitionContext:(id)context completion:(void (^)(BOOL))completion {
  if ([[RABackgrounder sharedInstance] hasUnlimitedBackgroundTime:scene.identifier] && settings.backgrounded && ![processAssertions objectForKey:scene.identifier]) {
    ProcessAssertionFlags flags = BKSProcessAssertionFlagPreventSuspend | BKSProcessAssertionFlagAllowIdleSleep | BKSProcessAssertionFlagPreventThrottleDownCPU | BKSProcessAssertionFlagWantsForegroundResourcePriority;
    keepAlive$temp = [[%c(BKSProcessAssertion) alloc] initWithPID:scene.clientProcess.pid flags:flags reason:BKSProcessAssertionReasonBackgroundUI name:@"reachapp" withHandler:^{
      LogInfo(@"ReachApp: %@ kept alive: %@", scene.identifier, keepAlive$temp.valid ? @"TRUE" : @"FALSE");
      if (keepAlive$temp.valid) {
        processAssertions[scene.identifier] = keepAlive$temp;
      }
    }];
  }

  %orig(scene, settings, diff, context, completion);
}
%end

@interface RAUnlimitedBackgroundingAppWatcher : NSObject <RARunningAppsStateObserver>
+ (void)load;
@end

static RAUnlimitedBackgroundingAppWatcher *sharedInstance$RAUnlimitedBackgroundingAppWatcher;

@implementation RAUnlimitedBackgroundingAppWatcher
+ (void)load {
  IF_NOT_SPRINGBOARD {
    return;
  }

  processAssertions = [NSMutableDictionary dictionary];

  sharedInstance$RAUnlimitedBackgroundingAppWatcher = [[RAUnlimitedBackgroundingAppWatcher alloc] init];
  [[RARunningAppsStateProvider defaultStateProvider] addObserver:sharedInstance$RAUnlimitedBackgroundingAppWatcher];
}

- (void)applicationDidExit:(NSString *)bundleIdentifier {
  if (![processAssertions objectForKey:bundleIdentifier]) {
    return;
  }

  [processAssertions[bundleIdentifier] invalidate];
  [processAssertions removeObjectForKey:bundleIdentifier];
}
@end
