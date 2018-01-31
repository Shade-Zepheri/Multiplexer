#import "RAHostedAppView.h"
#import "BioLockdown.h"
#import "RAHostManager.h"
#import "RAMessagingServer.h"
#import "RASnapshotProvider.h"
#import "RASpringBoardKeyboardActivation.h"
#import "Asphaleia.h"
#import "dispatch_after_cancel.h"
#import "UIAlertController+Window.h"

NSMutableDictionary *appsBeingHosted;

@interface RAHostedAppView () {
    //NSTimer *verifyTimer;
    BOOL isPreloading;
    FBWindowContextHostManager *contextHostManager;

    UIActivityIndicatorView *activityView;
    UIImageView *splashScreenImageView;

    UILabel *isForemostAppLabel;

    UILabel *authenticationDidFailLabel;
    UITapGestureRecognizer *authenticationFailedRetryTapGesture;

    int startTries;
    BOOL disablePreload;

    NSTimer *loadedTimer;
}
@end

@implementation RAHostedAppView
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier {
  self = [super init];
  if (self) {
    self.bundleIdentifier = bundleIdentifier;
    self.autosizesApp = NO;
    self.allowHidingStatusBar = YES;
    self.showSplashscreenInsteadOfSpinner = NO;
    startTries = 0;
    disablePreload = NO;
    self.renderWallpaper = NO;
    self.backgroundColor = [UIColor clearColor];
  }

  return self;
}

- (void)_preloadOrAttemptToUpdateReachabilityCounterpart {
  if (!app) {
    return;
  }

  if ([app mainScene]) {
    isPreloading = NO;
    if (((SBReachabilityManager *)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive && [GET_SBWORKSPACE respondsToSelector:@selector(RA_updateViewSizes)]) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [GET_SBWORKSPACE RA_updateViewSizes]; // App is launched using ReachApp - animations commence. We have to wait for those animations to finish or this won't work.
      });
    }
  } else if (![app mainScene]) {
    if (disablePreload) {
      disablePreload = NO;
    } else {
      [self preloadApp];
    }
  }
}

- (void)setBundleIdentifier:(NSString *)value {
  _orientation = UIInterfaceOrientationPortrait;
  _bundleIdentifier = value;
  app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:value];
}

- (void)setShouldUseExternalKeyboard:(BOOL)value {
  _shouldUseExternalKeyboard = value;
  [[RAMessagingServer mainMessagingServer] setShouldUseExternalKeyboard:value forApp:self.bundleIdentifier completion:nil];
}

- (void)preloadApp {
  startTries++;
  if (startTries > 5) {
    isPreloading = NO;
    LogError(@"[ReachApp] maxed out preload attempts for app %@", app.bundleIdentifier);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Multiplexer" message:[NSString stringWithFormat:@"Unable to start app %@", app.displayName] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:defaultAction];
    [alert show];
    return;
  }

  if (!app || _isCurrentlyHosting) {
    return;
  }

  isPreloading = YES;
  FBScene *scene = [app mainScene];
  if (![app pid] || !scene) {
    [[FBSSystemService sharedService] openApplication:self.bundleIdentifier options:@{ FBSOpenApplicationOptionKeyActivateSuspended : @YES } withResult:nil];
  }
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self _preloadOrAttemptToUpdateReachabilityCounterpart];
  });
  // this ^ runs either way. when _preloadOrAttemptToUpdateReachabilityCounterpart runs, if the app is "loaded" it will not call preloadApp again, otherwise
  // it will call it again.
}

- (void)_actualLoadApp {
  if (isPreloading) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [self _actualLoadApp];
    });
    return;
  }

  if (_isCurrentlyHosting) {
    return;
  }

  _isCurrentlyHosting = YES;

  appsBeingHosted[app.bundleIdentifier] = [appsBeingHosted objectForKey:app.bundleIdentifier] ? @([appsBeingHosted[app.bundleIdentifier] intValue] + 1) : @1;
  view = (FBWindowContextHostWrapperView *)[RAHostManager enabledHostViewForApplication:app];
  contextHostManager = (FBWindowContextHostManager *)[RAHostManager hostManagerForApp:app];
  view.backgroundColorWhileNotHosting = [UIColor clearColor];
  view.backgroundColorWhileHosting = [UIColor clearColor];

  view.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
  //view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [self addSubview:view];

  [[RAMessagingServer mainMessagingServer] setHosted:YES forIdentifier:app.bundleIdentifier completion:nil];
  if (IS_IPAD) {
    [RAHostedAppView iPad_iOS83_fixHosting];
  }

  [[RARunningAppsStateProvider defaultStateProvider] addObserver:self];

  loadedTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(verifyHostingAndRehostIfNecessary) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:loadedTimer forMode:NSRunLoopCommonModes];
}

- (void)loadApp {
  startTries = 0;
  disablePreload = NO;
  [self preloadApp];
  if (!app || _isCurrentlyHosting) {
    return;
  }

  if ([[UIApplication sharedApplication]._accessibilityFrontMostApplication isEqual:app]) {
    isForemostAppLabel = [[UILabel alloc] initWithFrame:self.bounds];
    isForemostAppLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    isForemostAppLabel.textColor = [UIColor whiteColor];
    isForemostAppLabel.textAlignment = NSTextAlignmentCenter;
    isForemostAppLabel.font = [UIFont systemFontOfSize:36];
    isForemostAppLabel.numberOfLines = 0;
    isForemostAppLabel.lineBreakMode = NSLineBreakByWordWrapping;
    isForemostAppLabel.text = [NSString stringWithFormat:LOCALIZE(@"ACTIVE_APP_WARNING", @"Localizable"), self.app.displayName];
    [self addSubview:isForemostAppLabel];
    return;
  }

  IF_BIOLOCKDOWN {
    id failedBlock = ^{
      [self removeLoadingIndicator];
      if (!authenticationDidFailLabel) {
          authenticationDidFailLabel = [[UILabel alloc] initWithFrame:self.bounds];
          authenticationDidFailLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
          authenticationDidFailLabel.textColor = [UIColor whiteColor];
          authenticationDidFailLabel.textAlignment = NSTextAlignmentCenter;
          authenticationDidFailLabel.font = [UIFont systemFontOfSize:36];
          authenticationDidFailLabel.numberOfLines = 0;
          authenticationDidFailLabel.lineBreakMode = NSLineBreakByWordWrapping;
          authenticationDidFailLabel.text = [NSString stringWithFormat:LOCALIZE(@"BIOLOCKDOWN_AUTH_FAILED", @"Localizable"), self.app.displayName];
          [self addSubview:authenticationDidFailLabel];

          authenticationFailedRetryTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadApp)];
          [self addGestureRecognizer:authenticationFailedRetryTapGesture];
          self.userInteractionEnabled = YES;
      }
    };

    BIOLOCKDOWN_AUTHENTICATE_APP(app.bundleIdentifier, ^{
      [self _actualLoadApp];
    }, failedBlock /* stupid commas */);
  } else IF_ASPHALEIA {
    void (^failedBlock)() = ^{
      [self removeLoadingIndicator];
      if (!authenticationDidFailLabel) {
        authenticationDidFailLabel = [[UILabel alloc] initWithFrame:self.bounds];
        authenticationDidFailLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        authenticationDidFailLabel.textColor = [UIColor whiteColor];
        authenticationDidFailLabel.textAlignment = NSTextAlignmentCenter;
        authenticationDidFailLabel.font = [UIFont systemFontOfSize:36];
        authenticationDidFailLabel.numberOfLines = 0;
        authenticationDidFailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        authenticationDidFailLabel.text = [NSString stringWithFormat:LOCALIZE(@"ASPHALEIA_AUTH_FAILED", @"Localizable"), self.app.displayName];
        [self addSubview:authenticationDidFailLabel];

        authenticationFailedRetryTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadApp)];
        [self addGestureRecognizer:authenticationFailedRetryTapGesture];
        self.userInteractionEnabled = YES;
      }
    };

    ASPHALEIA_AUTHENTICATE_APP(app.bundleIdentifier, ^{
      [self _actualLoadApp];
    }, failedBlock);
  } else {
    [self _actualLoadApp];
  }

  if (self.showSplashscreenInsteadOfSpinner) {
    if (splashScreenImageView) {
      [splashScreenImageView removeFromSuperview];
      splashScreenImageView = nil;
    }
    UIImage *img = [[RASnapshotProvider sharedInstance] snapshotForIdentifier:self.bundleIdentifier];
    splashScreenImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    splashScreenImageView.image = img;
    [self insertSubview:splashScreenImageView atIndex:0];
  } else {
    if (!activityView) {
      activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
      [self addSubview:activityView];
    }

    CGFloat size = 50;
    activityView.frame = CGRectMake((self.bounds.size.width - size) / 2, (self.bounds.size.height - size) / 2, size, size);

    [activityView startAnimating];
  }
}

- (void)verifyHostingAndRehostIfNecessary {
  if (!isPreloading && _isCurrentlyHosting && (!app.isRunning || !view.contextHosted)) { // && (app.pid == 0 || view == nil || view.manager == nil)) // || view._isReallyHosting == NO))
    //[activityView startAnimating];
    [self unloadApp];
    [self loadApp];
  } else {
    [self removeLoadingIndicator];
    [loadedTimer invalidate];
    loadedTimer = nil;
  }
}

- (void)applicationDidExit:(NSString *)bundleIdentifier {
  if (![self.bundleIdentifier isEqualToString:bundleIdentifier]) {
    return;
  }

  [self verifyHostingAndRehostIfNecessary];
}

- (void)removeLoadingIndicator {
  if (self.showSplashscreenInsteadOfSpinner) {
    [splashScreenImageView removeFromSuperview];
    splashScreenImageView = nil;
  } else if (activityView) {
    [activityView stopAnimating];
  }
}

- (void)drawRect:(CGRect)rect {
  if (!_renderWallpaper) {
    return;
  }
  [[[RASnapshotProvider sharedInstance] wallpaperImage] drawInRect:rect];
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  [view setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];

  if (self.autosizesApp) {
    RAMessageAppData data = [[RAMessagingServer mainMessagingServer] getDataForIdentifier:self.bundleIdentifier];
    data.canHideStatusBarIfWanted = self.allowHidingStatusBar;
    [[RAMessagingServer mainMessagingServer] setData:data forIdentifier:self.bundleIdentifier];
    [[RAMessagingServer mainMessagingServer] resizeApp:self.bundleIdentifier toSize:CGSizeMake(frame.size.width, frame.size.height) completion:nil];

  } else if (self.bundleIdentifier) {
    [[RAMessagingServer mainMessagingServer] endResizingApp:self.bundleIdentifier completion:nil];
  }
}

- (void)setHideStatusBar:(BOOL)value {
  _hideStatusBar = value;

  if (!self.bundleIdentifier) {
    return;
  }

  if (value) {
    [[RAMessagingServer mainMessagingServer] forceStatusBarVisibility:!value forApp:self.bundleIdentifier completion:nil];
  } else {
    [[RAMessagingServer mainMessagingServer] unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:nil];
  }
}

- (void)unloadApp {
  [self unloadApp:NO];
}

- (void)unloadApp:(BOOL)forceImmediate {
  //if (activityView)
  //    [activityView stopAnimating];
  [self removeLoadingIndicator];
  [loadedTimer invalidate];
  loadedTimer = nil;

  [[RARunningAppsStateProvider defaultStateProvider] removeObserver:self];

  disablePreload = YES;

  if (!_isCurrentlyHosting) {
    return;
  }

  _isCurrentlyHosting = NO;

  FBScene *scene = [app mainScene];

  if (authenticationDidFailLabel) {
    [authenticationDidFailLabel removeFromSuperview];
    authenticationDidFailLabel = nil;

    [self removeGestureRecognizer:authenticationFailedRetryTapGesture];
    self.userInteractionEnabled = NO;
  }

  if (isForemostAppLabel) {
    [isForemostAppLabel removeFromSuperview];
    isForemostAppLabel = nil;
  }

  if ([[RASpringBoardKeyboardActivation sharedInstance].currentIdentifier isEqualToString:self.bundleIdentifier]) {
    [[RASpringBoardKeyboardActivation sharedInstance] hideKeyboard];
  }

  if (contextHostManager) {
    [contextHostManager disableHostingForRequester:@"reachapp"];
    contextHostManager = nil;
  }

  //if ([UIApplication.sharedApplication._accessibilityFrontMostApplication isEqual:app])
  //    return;

  __weak RAHostedAppView *weakSelf = self;
  __block BOOL didRun = NO;
  RAMessageCompletionCallback block = ^(BOOL success) {
    if (didRun || (weakSelf && [[UIApplication sharedApplication]._accessibilityFrontMostApplication isEqual:weakSelf.app])) {
      return;
    }
    if (!scene) {
      return;
    }

    appsBeingHosted[app.bundleIdentifier] = [appsBeingHosted objectForKey:app.bundleIdentifier] ? @([appsBeingHosted[app.bundleIdentifier] intValue] - 1) : @0;

    if ([appsBeingHosted[app.bundleIdentifier] intValue] > 0) {
      return;
    }

    FBSMutableSceneSettings *settings = scene.mutableSettings;
    settings.backgrounded = YES;
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
    //FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
    didRun = YES;
  };

  [[RAMessagingServer mainMessagingServer] setHosted:NO forIdentifier:app.bundleIdentifier completion:nil];
  [[RAMessagingServer mainMessagingServer] unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:nil];
  [[RAMessagingServer mainMessagingServer] unRotateApp:self.bundleIdentifier completion:nil];
  if (forceImmediate) {
    [[RAMessagingServer mainMessagingServer] endResizingApp:self.bundleIdentifier completion:nil];
    block(YES);
  } else {
    // >Somewhere in the messaging server, the block is being removed from the waitingCompletions dictionary without being called.
    // >This is a large issue (probably to do with asynchronous code) TODO: FIXME
    // lol im retarded, it's the default empty callback the messaging server made
    //[[RAMessagingServer mainMessagingServer] unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:block];
    //[[RAMessagingServer mainMessagingServer] unRotateApp:self.bundleIdentifier completion:block];

    [[RAMessagingServer mainMessagingServer] endResizingApp:self.bundleIdentifier completion:block];
  }
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
  _orientation = orientation;

  [[RAMessagingServer mainMessagingServer] rotateApp:self.bundleIdentifier toOrientation:orientation completion:nil];
}

+ (void)iPad_iOS83_fixHosting {
  //Doesnt appear to be necessary on iOS 10 (check if necessary on iOS 9)? Causes problems on iPhone and FPM
  for (NSString *bundleIdentifier in appsBeingHosted.allKeys) {
    NSNumber *num = appsBeingHosted[bundleIdentifier];
    if (num.intValue > 0) {
      SBApplication *app_ = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
      FBWindowContextHostManager *manager = (FBWindowContextHostManager *)[RAHostManager hostManagerForApp:app_];
      if (manager) {
        LogInfo(@"[ReachApp] rehosting for iPad: %@", bundleIdentifier);
        [manager enableHostingForRequester:@"reachapp" priority:1];
      }
    }
  }
}

// This allows for any subviews (with gestures) (e.g. the SwipeOver bar with a negative y origin) to recieve touch events.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  BOOL isContained = NO;
  for (UIView *subview in self.subviews) {
    if (CGRectContainsPoint(subview.frame, point)) { // [self convertPoint:point toView:view]))
      isContained = YES;
    }
  }
  return isContained;
}

- (SBApplication *)app {
  return app;
}

- (NSString *)displayName {
  return app.displayName;
}

@end

%ctor {
  appsBeingHosted = [NSMutableDictionary dictionary];
}
