#import "headers.h"
#import "RABackgrounder.h"
#import "RAAppSwitcherModelWrapper.h"
#import "Multiplexer.h"

%hook SBApplication
- (BOOL)shouldAutoRelaunchAfterExit {
  return [[RABackgrounder sharedInstance] shouldAutoRelaunchApplication:self.bundleIdentifier] || %orig;
}

- (BOOL)shouldAutoLaunchOnBootOrInstall {
  return [[RABackgrounder sharedInstance] shouldAutoLaunchApplication:self.bundleIdentifier] || %orig;
}

- (BOOL)_shouldAutoLaunchOnBootOrInstall:(BOOL)value {
  return [[RABackgrounder sharedInstance] shouldAutoLaunchApplication:self.bundleIdentifier] || %orig;
}
%end

// STAY IN "FOREGROUND"
%hook FBUIApplicationSceneDeactivationManager // iOS 9
- (BOOL)_isEligibleProcess:(FBApplicationProcess *)process {
  if ([[RABackgrounder sharedInstance] shouldKeepInForeground:process.bundleIdentifier]) {
    return NO;
  }

  return %orig;
}
%end

%hook FBUIApplicationService
- (void)handleSuspendApplicationProcess:(FBApplicationProcess *)process {
  if ([[RABackgrounder sharedInstance] shouldKeepInForeground:process.bundleIdentifier]) {
    return;
  }

  %orig;
}
%end

%hook FBSSceneImpl
- (instancetype)initWithQueue:(id)queue identifier:(NSString *)identifier display:(FBSDisplay *)display settings:(UIMutableApplicationSceneSettings *)settings clientSettings:(id)clientSettings {
  if ([[RABackgrounder sharedInstance] shouldKeepInForeground:identifier]) {
    // what?
    if (!settings) {
      UIMutableApplicationSceneSettings *fakeSettings = [[%c(UIMutableApplicationSceneSettings) alloc] init];
      settings = fakeSettings;
    }

    settings.backgrounded = NO;
  }

  return %orig(queue, identifier, display, settings, clientSettings);
}

- (BOOL)invalidateSnapshotWithContext:(FBSSceneSnapshotContext *)context {
  return [[RABackgrounder sharedInstance] globalBackgroundMode] == RABackgroundModeSuspendImmediately ? YES : %orig;
}
%end

%hook FBUIApplicationWorkspaceScene
- (void)host:(FBScene *)scene didUpdateSettings:(FBSSceneSettings *)settings withDiff:(id)diff transitionContext:(id)context completion:(void (^)(BOOL))completion {
  if (scene && scene.identifier && settings && scene.clientProcess) {
    if (settings.backgrounded) {
      if ([[RABackgrounder sharedInstance] killProcessOnExit:scene.identifier]) {
        FBProcess *proc = scene.clientProcess;

        if ([proc isKindOfClass:%c(FBApplicationProcess)]) {
          FBApplicationProcess *proc2 = (FBApplicationProcess *)proc;
          [proc2 killForReason:1 andReport:NO withDescription:@"ReachApp.Backgrounder.killOnExit"];
          [[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:scene.identifier withInfo:RAIconIndicatorViewInfoForceDeath];
          if ([[RABackgrounder sharedInstance] shouldRemoveFromSwitcherWhenKilledOnExit:scene.identifier]) {
            [RAAppSwitcherModelWrapper removeItemWithIdentifier:scene.identifier];
          }
        }
      }

      [[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:scene.identifier withInfo:[[RABackgrounder sharedInstance] allAggregatedIndicatorInfoForIdentifier:scene.identifier]];
      [[RABackgrounder sharedInstance] queueRemoveTemporaryOverrideForIdentifier:scene.identifier];

      if ([[RABackgrounder sharedInstance] shouldKeepInForeground:scene.identifier]) {
        return;
      }
    }
  }

  %orig(scene, settings, diff, context, completion);
}
%end

%hook FBSceneManager
- (void)_noteSceneMovedToForeground:(FBScene *)scene {
  if ([scene.clientProcess isKindOfClass:%c(FBApplicationProcess)]) {
    [[RABackgrounder sharedInstance] removeTemporaryOverrideForIdentifier:scene.identifier];
  }

  %orig;
}

- (void)_noteSceneMovedToBackground:(FBScene *)scene {
  %orig;

  if ([[RABackgrounder sharedInstance] shouldSuspendImmediately:scene.identifier] && [scene.clientProcess isKindOfClass:%c(FBApplicationProcess)]) {
    FBApplicationProcess *process = (FBApplicationProcess *)scene.clientProcess;
    BKSProcess *bkProcess = [process valueForKey:@"_bksProcess"];
    [process processWillExpire:bkProcess];
  }
}
%end

// PREVENT KILLING
%hook FBApplicationProcess
- (void)killForReason:(NSInteger)reason andReport:(BOOL)report withDescription:(NSString *)description completion:(id)completion {
  if ([[RABackgrounder sharedInstance] preventKillingOfIdentifier:self.bundleIdentifier]) {
    [[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[[RABackgrounder sharedInstance] allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
    return;
  }

  %orig;
}
%end

%hook SpringBoard
- (void)_performDeferredLaunchWork {
  %orig;

  [[Multiplexer sharedInstance] registerExtension:@"com.shade.aura" forMultiplexerVersion:@"1.0.0"];
}
%end

%ctor {
  IF_NOT_SPRINGBOARD {
    return;
  }

  %init;
}
