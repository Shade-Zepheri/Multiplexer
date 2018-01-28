#import "RANCViewController.h"
#import "RAHostedAppView.h"
#import "RASettings.h"

@interface RANCViewController ()
@property (strong, nonatomic) RAHostedAppView *appView;
@property (strong, nonatomic)	UILabel *isLockedLabel;
@end

@implementation RANCViewController

+ (instancetype)defaultViewController {
	SHARED_INSTANCE(RANCViewController);
}

- (void)forceReloadAppLikelyBecauseTheSettingChanged {
/*
	[self.appView unloadApp];
	[self.appView removeFromSuperview];
	self.appView = nil;
*/
}


int patchOrientation(int in) {
	if (in == 3) {
		return 1;
	}

	return in;
}

int rotationDegsForOrientation(int o) {
	if (o == UIInterfaceOrientationLandscapeRight) {
		return 270;
	} else if (o == UIInterfaceOrientationLandscapeLeft) {
		return 90;
	}
	return 0;
}

//-(void)hostWillPresent;
//-(void)hostDidPresent;
//-(void)hostWillDismiss;
//-(void)hostDidDismiss;

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

  //Major changes in iOS 11 so gotta account for that
	NSString *identifier = [[RASettings sharedInstance] NCApp];
	SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
	SBWorkspaceApplication *workspaceApplication = [%c(SBWorkspaceApplication) entityForApplication:application];
	_appViewController = [[%c(SBAppViewController) alloc] initWithIdentifier:identifier andApplication:workspaceApplication];
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

	if (_appViewController.requestedMode != 2) {
		_appViewController.requestedMode = 1;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	_appViewController.requestedMode = 2;
	[_appViewController.appView setForcesStatusBarHidden:YES];

	UIView *contentView = _appViewController.view;

  //Get scale before resize
	CGFloat scale = CGRectGetHeight(contentView.frame) / CGRectGetHeight([UIScreen mainScreen].bounds);

  contentView.frame = [UIScreen mainScreen].bounds;
  contentView.center = self.view.center;
	contentView.transform = CGAffineTransformMakeScale(scale, scale);

/*
	if ([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
		if (!self.isLockedLabel) {
			self.isLockedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
			self.isLockedLabel.numberOfLines = 2;
			self.isLockedLabel.textAlignment = NSTextAlignmentCenter;
			self.isLockedLabel.textColor = [UIColor whiteColor];
			self.isLockedLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 36 : 30];
			[self.view addSubview:self.isLockedLabel];
		}

		self.isLockedLabel.frame = CGRectMake((self.view.frame.size.width - self.isLockedLabel.frame.size.width) / 2, (self.view.frame.size.height - self.isLockedLabel.frame.size.height) / 2, self.isLockedLabel.frame.size.width, self.isLockedLabel.frame.size.height);

		self.isLockedLabel.text = LOCALIZE(@"UNLOCK_FOR_NCAPP", @"Localizable");
		return;
	} else if (self.isLockedLabel) {
		[self.isLockedLabel removeFromSuperview];
		self.isLockedLabel = nil;
	}

	if (!self.appView) {
		NSString *ident = [[RASettings sharedInstance] NCApp];
		self.appView = [[RAHostedAppView alloc] initWithBundleIdentifier:ident];
		self.appView.frame = [UIScreen mainScreen].bounds;
		[self.view addSubview:self.appView];

		[self.appView preloadApp];
	}

	[self.appView loadApp];
	self.appView.hideStatusBar = YES;

	if (NO) {// (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
		self.appView.autosizesApp = YES;
		self.appView.allowHidingStatusBar = YES;
		self.appView.transform = CGAffineTransformIdentity;
		self.appView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	} else {
		self.appView.autosizesApp = NO;
		self.appView.allowHidingStatusBar = YES;

		// Reset
		self.appView.transform = CGAffineTransformIdentity;
		self.appView.frame = [UIScreen mainScreen].bounds;

		self.appView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(rotationDegsForOrientation([UIApplication sharedApplication].statusBarOrientation))); // Explicitly, SpringBoard's status bar since the NC is shown in SpringBoard
		CGFloat scale = self.view.frame.size.height / [UIScreen mainScreen].bounds.size.height;
		self.appView.transform = CGAffineTransformScale(self.appView.transform, scale, scale);

		// Align vertically
		CGRect f = self.appView.frame;
		f.origin.y = 0;
		if (IS_IOS_OR_NEWER(iOS_10_0) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) { //really hacky but u gotta do what ya gotta do
			f.origin.x = (self.view.frame.size.width - f.size.height) / 2.0;
		} else {
			f.origin.x = (self.view.frame.size.width - f.size.width) / 2.0;
		}
		self.appView.frame = f;
	}
	//[appView rotateToOrientation:UIApplication.sharedApplication.statusBarOrientation];


	if (IS_IOS_BETWEEN(iOS_9_0, iOS_9_3)) { // Must manually place view controller :(
		CGRect frame = self.view.frame;
		frame.origin.x = [UIScreen mainScreen].bounds.size.width * 2.0;
		self.view.frame = frame;
	}
*/
}
/*
- (void)hostDidDismiss {
	if (!self.appView.isCurrentlyHosting) {
		return;
	}

	self.appView.hideStatusBar = NO;
	[self.appView unloadApp];
}
*/
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	_appViewController.requestedMode = 0;
/*
	self.appView.hideStatusBar = NO;
	if (self.appView.isCurrentlyHosting) {
		[self.appView unloadApp];
	}
*/
}

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
