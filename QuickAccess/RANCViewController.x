#import "RANCViewController.h"
#import "RAHostedAppView.h"
#import "RASettings.h"

@interface RANCViewController ()
@property (strong, nonatomic)	UILabel *isLockedLabel;
@end

@implementation RANCViewController

+ (instancetype)defaultViewController {
	SHARED_INSTANCE(RANCViewController);
}

- (void)forceReloadAppLikelyBecauseTheSettingChanged {
  //Reload app when settings change (Maybe not necessary cuz prompts respring anyways)
}

- (void)insertAppropriateViewWithContent {
	[self viewDidAppear:YES];
}

- (SBApplication *)hostedApp {
	return [_appViewController hostedApp];
}

- (BOOL)isHostingAnApp {
	return [_appViewController isHostingAnApp];
}

- (BOOL)canHostAnApp {
	return [_appViewController canHostAnApp];
}

- (void)hostedAppWillRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	[_appViewController hostedAppWillRotateToInterfaceOrientation:orientation];
}

- (void)loadView {
	[super loadView];

	NSString *identifier = [[RASettings sharedInstance] NCApp];
  SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];

  if ([%c(SBAppViewController) instancesRespondToSelector:@selector(initWithIdentifier:andApplicationSceneEntity:)]) {
    SBDeviceApplicationSceneEntity *applicationSceneEntity = [[%c(SBDeviceApplicationSceneEntity) alloc] initWithApplicationForMainDisplay:application];
    _appViewController = [[%c(SBAppViewController) alloc] initWithIdentifier:identifier andApplicationSceneEntity:applicationSceneEntity];
  } else {
    SBWorkspaceApplication *workspaceApplication = [%c(SBWorkspaceApplication) entityForApplication:application];
    _appViewController = [[%c(SBAppViewController) alloc] initWithIdentifier:identifier andApplication:workspaceApplication];
  }

	_appViewController.automatesLifecycle = NO;
	_appViewController.ignoresOcclusions = YES;
	_appViewController.options = 65537;

	[self bs_addChildViewController:_appViewController animated:NO transitionBlock:^{
		[self.view addSubview:_appViewController.view];
	}];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];

  //Hacky fix for frame size
  self.view.frame = self.view.superview.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

  _appViewController.requestedMode = 2;
	if (_appViewController.requestedMode != 2) {
		_appViewController.requestedMode = 1;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

  if ([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
		if (!self.isLockedLabel) {
			self.isLockedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
			self.isLockedLabel.numberOfLines = 2;
			self.isLockedLabel.textAlignment = NSTextAlignmentCenter;
			self.isLockedLabel.textColor = [UIColor whiteColor];
			self.isLockedLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 36 : 30];
			[self.view addSubview:self.isLockedLabel];
		}

		self.isLockedLabel.center = self.view.center;
		self.isLockedLabel.text = LOCALIZE(@"UNLOCK_FOR_NCAPP", @"Localizable");
		return;
	} else if (self.isLockedLabel) {
		[self.isLockedLabel removeFromSuperview];
		self.isLockedLabel = nil;
	}

	_appViewController.requestedMode = 2;
	[_appViewController.appView setForcesStatusBarHidden:YES];

	UIView *contentView = _appViewController.view;

  contentView.transform = CGAffineTransformIdentity;
  contentView.frame = [UIScreen mainScreen].bounds;

	CGFloat scale = CGRectGetHeight(self.view.frame) / CGRectGetHeight([UIScreen mainScreen].bounds);
	contentView.transform = CGAffineTransformMakeScale(scale, scale);
  contentView.center = self.view.center;
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	_appViewController.requestedMode = 1;
}

//TODO: See if iOS 9 needs these methods
- (void)forwardInvocation:(NSInvocation *)anInvocation {
	// Override
	LogDebug(@"RANCViewController: ignoring invocation: %@", anInvocation);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
	if (!signature && class_respondsToSelector(%c(SBBulletinObserverViewController), aSelector)) {
		signature = [%c(SBBulletinObserverViewController) instanceMethodSignatureForSelector:aSelector];
	}

	return signature;
}

- (BOOL)isKindOfClass:(Class)aClass {
	if (aClass == %c(SBBulletinObserverViewController) || aClass == %c(SBNCColumnViewController)) {
		return YES;
	} else {
		return [super isKindOfClass:aClass];
	}
}

- (void)dealloc {
	[_appViewController invalidate];
}

@end
