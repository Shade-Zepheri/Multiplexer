#import "RANCViewController.h"
#import "RAHostedAppView.h"
#import "RASettings.h"
#import "headers.h"
#import "Multiplexer.h"

NSString *getAppName() {
	NSString *ident = [[RASettings sharedInstance] NCApp] ?: @"com.apple.Preferences";
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:ident];
	return app ? app.displayName : nil;
}

static RANCViewController *ncAppViewController;

%group iOS9
%hook SBNotificationCenterLayoutViewController

- (void)viewWillAppear:(BOOL)animated {
	%orig;

	BOOL hideBecauseLS = [[%c(SBLockScreenManager) sharedInstance] isUILocked] ? [[RASettings sharedInstance] ncAppHideOnLS] : NO;

	if ([[RASettings sharedInstance] NCAppEnabled] && !hideBecauseLS) {
		SBModeViewController *modeVC = self.modeViewController;
		if (!ncAppViewController) {
			ncAppViewController = [RANCViewController defaultViewController];
		}
		[modeVC _addBulletinObserverViewController:ncAppViewController];
	}
}

%end

// This is more of a hack than anything else. Note that `_localizableTitleForColumnViewController` on iOS 9 does not seem to work (I may be doing something else wrong)
// if more than one custom nc tab is added, this will not work correctly.
%hook SBModeViewController

- (void)_layoutHeaderViewIfNecessary {
	%orig;

	NSString *text = @"";
	BOOL useGenericLabel = THEMED(quickAccessUseGenericTabLabel) || [[RASettings sharedInstance] quickAccessUseGenericTabLabel];
	if (useGenericLabel) {
		text = LOCALIZE(@"APP", @"Localizable");
	} else {
		text = ncAppViewController.hostedApp.displayName ?: getAppName() ?: LOCALIZE(@"APP", @"Localizable");
	}

	for (UIView *view in [[self valueForKey:@"_headerView"] subviews]) {
		if ([view isKindOfClass:[UISegmentedControl class]]) {
			UISegmentedControl *segment = (UISegmentedControl *)view;
			if (segment.numberOfSegments > 2) {
				[segment setTitle:text forSegmentAtIndex:2];
			}
		}
	}
}

%end
%end

%group iOS10 //Major changes in iOS 11
static UIView *ncAppContentView;

//This whole process could be simplified to 1 hook, but this is how SB adds its VCs
%hook SBSearchEtceteraLayoutView

- (instancetype)initWithFrame:(CGRect)frame {
	SBSearchEtceteraLayoutView *orig = %orig;
	if (orig) {
		SBPagedScrollView *scrollView = orig.scrollView;
		NSMutableArray *mutablePageViews = [scrollView.pageViews mutableCopy];

		ncAppContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
		[mutablePageViews addObject:ncAppContentView];
		scrollView.pageViews = [mutablePageViews copy];
	}

	return orig;
}

%end

%hook SBSearchEtceteraIsolatedViewController

- (void)_createMultiplexedChildViewControllers {
	%orig;

	if (!ncAppViewController) {
		ncAppViewController = [RANCViewController defaultViewController];
	}

	[self addChildViewController:ncAppViewController];
	[ncAppContentView addSubview:ncAppViewController.view];
	[ncAppViewController didMoveToParentViewController:self];
}

// Hacky way get SVSEIVC to get the VC
- (UIViewController *)viewControllerForMode:(NSUInteger)mode {
	if (mode != 0) {
		return %orig;
	}

	return ncAppViewController;
}

%end

%hook SBNotificationCenterViewController

- (void)_loadPageControl {
	%orig;

  // minor hook to have it show 3 dots
	UIPageControl *pageControl = self.pageControl;
	pageControl.numberOfPages += 1;
}

%end
%end

%hook SpringBoard

- (void)_performDeferredLaunchWork {
	%orig;

	[[Multiplexer sharedInstance] registerExtension:@"com.shade.quickaccess" forMultiplexerVersion:@"1.0.0"];
}

%end

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		%init(iOS10);
	} else {
		%init(iOS9);
	}

	%init;
}
