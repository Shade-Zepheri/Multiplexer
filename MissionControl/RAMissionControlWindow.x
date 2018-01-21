#import "RAMissionControlWindow.h"
#import "RAMissionControlPreviewView.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RASnapshotProvider.h"
#import "RAWindowBar.h"
#import "RAAppKiller.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "RAMissionControlManager.h"
#import "RASettings.h"
#import "RAResourceImageProvider.h"
#import "RARunningAppsStateProvider.h"
#import "RAAppSwitcherModelWrapper.h"

@interface RAMissionControlWindow ()  {
	UIScrollView *desktopScrollView, *windowedAppScrollView, *otherRunningAppsScrollView;
	UILabel *desktopLabel, *windowedLabel, *otherLabel;
	UIButton *windowedKillAllButton, *otherKillAllButton;

	UIImageView *trashImageView;
	UIView *shadowView;
	UIImage *trashIcon;

	NSMutableArray *appsWithoutWindows;

	CGFloat width, height;
	CGFloat panePadding;
}
@end

@implementation RAMissionControlWindow
- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		trashIcon = [RAResourceImageProvider imageForFilename:@"Trash.png"];
		self.windowLevel = 1000;
	}

	return self;
}

- (BOOL)_shouldAutorotateToInterfaceOrientation:(NSInteger)orientation checkForDismissal:(BOOL)check isRotationDisabled:(BOOL*)value {
	return YES;
}

- (void)reloadDesktopSection {
	width = self.frame.size.width / 4.5714;
	height = self.frame.size.height / 4.36;
	panePadding = width;
	int count = 1;
	while (panePadding + width < self.frame.size.width) {
		count += 1;
		panePadding += width;
	}
	panePadding = (self.frame.size.width - panePadding) / 5;
	/*if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		width = ([UIScreen mainScreen].bounds.size.width / 3) * 0.9;
	    height = ([UIScreen mainScreen].bounds.size.height / 4) * 0.9;
	}*/

	// DESKTOP
	CGFloat y = 20;

	if (desktopScrollView) {
		[desktopScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	} else {
		desktopLabel = [[UILabel alloc] initWithFrame:CGRectMake(panePadding, y, self.frame.size.width - 20, 25)];
		desktopLabel.font = [UIFont fontWithName:(IS_IOS_OR_NEWER(iOS_9_0) ? @"SFUIText-Medium" : @"HelveticaNeue-Medium") size:14];
		desktopLabel.textColor = [UIColor whiteColor];
		desktopLabel.text = LOCALIZE(@"DESKTOPS", @"Localizable");
		[self addSubview:desktopLabel];

		y = y + desktopLabel.frame.size.height;

		desktopScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, height * 1.15)];
		desktopScrollView.backgroundColor = [THEMED(missionControlScrollViewBackgroundColor) colorWithAlphaComponent:THEMED(missionControlScrollViewOpacity)];
		desktopScrollView.pagingEnabled = [[RASettings sharedInstance] missionControlPagingEnabled];

		[self addSubview:desktopScrollView];
	}

	CGFloat x = panePadding;
	int desktopIndex = 0;
	for (RADesktopWindow *desktop in [[%c(RADesktopManager) sharedInstance] availableDesktops]) {
		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, (desktopScrollView.frame.size.height - height) / 2.0, width, height)];
		x += panePadding + preview.frame.size.width;
		preview.alpha = 0;

		[UIView animateWithDuration:1 animations:^{
			preview.alpha = 1;
		} completion:^(BOOL finished) {
			[desktopScrollView addSubview:preview];
		}];
		//preview.image = [[%c(RASnapshotProvider) sharedInstance] snapshotForDesktop:desktop];
		[preview generateDesktopPreviewAsync:desktop completion:desktop == [[%c(RADesktopManager) sharedInstance] currentDesktop] ? ^{
			dispatch_async(dispatch_get_main_queue(), ^{
				[[%c(RADesktopManager) sharedInstance] hideDesktop];
			});
		} : (dispatch_block_t)nil];

		if (desktop == [[%c(RADesktopManager) sharedInstance] currentDesktop] && [[RASettings sharedInstance] missionControlDesktopStyle] == 0) {
			preview.backgroundColor = [UIColor grayColor];
			preview.clipsToBounds = YES;
			preview.layer.borderWidth = 2;
			preview.layer.cornerRadius = 10;
			preview.layer.borderColor = [UIColor whiteColor].CGColor;
		} else if (desktop != [[%c(RADesktopManager) sharedInstance] currentDesktop] && [[RASettings sharedInstance] missionControlDesktopStyle] == 1) {
			UIView *crapView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(preview.frame), CGRectGetHeight(preview.frame))];
			crapView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
			[preview addSubview:crapView];
		}

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleDesktopTap:)];
		g.numberOfTapsRequired = 1;
		[preview addGestureRecognizer:g];

		UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(handleDoubleDesktopTap:)];
		doubleTap.numberOfTapsRequired = 2;
		[preview addGestureRecognizer:doubleTap];

		[g requireGestureRecognizerToFail:doubleTap];

		UIPanGestureRecognizer *swipeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDesktopPan:)];
		[preview addGestureRecognizer:swipeGesture];

		preview.tag = desktopIndex++;
		preview.userInteractionEnabled = YES;
	}

	UIButton *newDesktopButton = [UIButton buttonWithType:UIButtonTypeCustom];
	newDesktopButton.frame = CGRectMake(x, (desktopScrollView.frame.size.height - height) / 2.0, width, height);
	newDesktopButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2]; //[UIColor darkGrayColor];
	[newDesktopButton setTitle:@"+" forState:UIControlStateNormal];
	newDesktopButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[newDesktopButton addTarget:self action:@selector(createNewDesktop:) forControlEvents:UIControlEventTouchUpInside];
	[desktopScrollView addSubview:newDesktopButton];
	x += 20 + newDesktopButton.frame.size.width;

	desktopScrollView.contentSize = CGSizeMake(MAX(x, self.frame.size.width + 1), height * 1.15); // make slightly scrollable

	// We do this AFTER rendering the desktop
	//[RADesktopManager.sharedInstance hideDesktop];
	// ^^ see the generateDesktopPreviewAsync:completion: call about 40 lines up

	//width = [UIScreen mainScreen].bounds.size.width / 4.5714;
	//height = [UIScreen mainScreen].bounds.size.height / 4.36;
}

- (void)reloadWindowedAppsSection {
	NSArray *runningApplications = [RARunningAppsStateProvider defaultStateProvider].runningApps;
	[self reloadWindowedAppsSection:runningApplications];
}

- (void)reloadWindowedAppsSection:(NSArray *)runningApplications {
	NSMutableArray *sortedRunningApps = [runningApplications mutableCopy];

	NSArray *switcherOrder = [[RAAppSwitcherModelWrapper appSwitcherAppIdentiferList] copy];
	[sortedRunningApps sortUsingComparator:^NSComparisonResult(SBApplication *obj1, SBApplication *obj2) {
		return [@([switcherOrder indexOfObject:obj1.bundleIdentifier]) compare:@([switcherOrder indexOfObject:obj2.bundleIdentifier])];
	}];

	appsWithoutWindows = [sortedRunningApps mutableCopy];
	SBIconModel *iconModel = [[%c(SBIconController) sharedInstance] valueForKey:@"_iconModel"];
	NSArray *visibleIcons = iconModel.visibleIconIdentifiers;

	for (SBApplication *app in sortedRunningApps) {
		if ([visibleIcons containsObject:app.bundleIdentifier]) {
			continue;
		}// || [RAMissionControlManager.sharedInstance.inhibitedApplications containsObject:app.bundleIdentifier])
		[appsWithoutWindows removeObject:app];
	}

	CGFloat x = panePadding;
	CGFloat y = desktopScrollView.frame.origin.y + desktopScrollView.frame.size.height + 7;

	if (windowedAppScrollView) {
		[windowedAppScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	} else {
		windowedLabel = [[UILabel alloc] initWithFrame:CGRectMake(panePadding, y, self.frame.size.width - 20, 25)];
		windowedLabel.font = [UIFont fontWithName:(IS_IOS_OR_NEWER(iOS_9_0) ? @"SFUIText-Medium" : @"HelveticaNeue-Medium") size:14];
		windowedLabel.textColor = [UIColor whiteColor];
		windowedLabel.text = LOCALIZE(@"ON_THIS_DESKTOP", @"Localizable");
		[self addSubview:windowedLabel];

		windowedAppScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + windowedLabel.frame.size.height, self.frame.size.width, height * 1.15)];
		windowedAppScrollView.backgroundColor = [THEMED(missionControlScrollViewBackgroundColor) colorWithAlphaComponent:THEMED(missionControlScrollViewOpacity)];
		windowedAppScrollView.pagingEnabled = [[RASettings sharedInstance] missionControlPagingEnabled];

		[self addSubview:windowedAppScrollView];
	}

	BOOL empty = YES;
	for (RAHostedAppView *app in [[%c(RADesktopManager) sharedInstance] currentDesktop].appViews) {
		SBApplication *sbapp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:app.bundleIdentifier];
		[appsWithoutWindows removeObject:sbapp];

		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, (windowedAppScrollView.frame.size.height - height) / 2, width, height)];
		x += panePadding + preview.frame.size.width;

		preview.application = sbapp;
		[UIView animateWithDuration:1 animations:^{
			preview.alpha = 1;
		} completion:^(BOOL finished) {
			[windowedAppScrollView addSubview:preview];
		}];
		[preview generatePreviewAsync];

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topIconViewTap:)];
		[preview addGestureRecognizer:g];

		UILongPressGestureRecognizer *swipeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleAppPreviewPan:)];
		swipeGesture.minimumPressDuration = 0.1;
		[preview addGestureRecognizer:swipeGesture];

		preview.userInteractionEnabled = YES;
		empty = NO;
	}

	if (empty) {
		UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (windowedAppScrollView.frame.size.height - 30) / 2, windowedAppScrollView.frame.size.width, 30)];
		emptyLabel.textAlignment = NSTextAlignmentCenter;
		emptyLabel.font = [UIFont systemFontOfSize:25];
		emptyLabel.text = LOCALIZE(@"NO_APPS", @"Localizable");
		emptyLabel.textColor = [UIColor whiteColor];
		emptyLabel.alpha = 0.7;
		[windowedAppScrollView addSubview:emptyLabel];

		if (windowedKillAllButton) {
			[windowedKillAllButton removeFromSuperview];
			windowedKillAllButton = nil;
		}
	} else {
		if (!windowedKillAllButton) {
			windowedKillAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[windowedKillAllButton setTitle:LOCALIZE(@"KILL_ALL", @"Localizable") forState:UIControlStateNormal];
			windowedKillAllButton.titleLabel.font = [UIFont fontWithName:(IS_IOS_OR_NEWER(iOS_9_0) ? @"SFUIText-Medium" : @"HelveticaNeue-Medium") size:14];
			windowedKillAllButton.titleLabel.textColor = [UIColor whiteColor];
			[windowedKillAllButton sizeToFit];
			windowedKillAllButton.frame = CGRectMake(self.frame.size.width - panePadding - windowedKillAllButton.frame.size.width, y, windowedKillAllButton.frame.size.width, windowedKillAllButton.frame.size.height);
			[windowedKillAllButton addTarget:self action:@selector(killAllWindowed) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:windowedKillAllButton];
		}
	}
	windowedAppScrollView.contentSize = CGSizeMake(MAX(x, self.frame.size.width + (empty ? 0 : 1)), height * 1.15); // make slightly scrollable
}

- (void)reloadOtherAppsSection {
	CGFloat x = panePadding;
	CGFloat y = windowedAppScrollView.frame.origin.y + windowedAppScrollView.frame.size.height + 7;

	if (otherRunningAppsScrollView) {
		[otherRunningAppsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	} else {
		otherLabel = [[UILabel alloc] initWithFrame:CGRectMake(panePadding, y, self.frame.size.width - 20, 25)];
		otherLabel.font = [UIFont fontWithName:(IS_IOS_OR_NEWER(iOS_9_0) ? @"SFUIText-Medium" : @"HelveticaNeue-Medium") size:14];
		otherLabel.textColor = [UIColor whiteColor];
		otherLabel.text = LOCALIZE(@"RUNNING_ELSEWHERE", @"Localizable");
		[self addSubview:otherLabel];

		otherRunningAppsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + otherLabel.frame.size.height, self.frame.size.width, height * 1.15)];
		otherRunningAppsScrollView.backgroundColor = [THEMED(missionControlScrollViewBackgroundColor) colorWithAlphaComponent:THEMED(missionControlScrollViewOpacity)];
		otherRunningAppsScrollView.pagingEnabled = [[RASettings sharedInstance] missionControlPagingEnabled];

		[self addSubview:otherRunningAppsScrollView];
	}

	BOOL empty = YES;
	for (SBApplication *app in appsWithoutWindows) {
		empty = NO;

		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, (otherRunningAppsScrollView.frame.size.height - height) / 2, width, height)];
		x += panePadding + preview.frame.size.width;

		preview.application = app;
		[UIView animateWithDuration:1 animations:^{
			preview.alpha = 1;
		} completion:^(BOOL finished) {
			[otherRunningAppsScrollView addSubview:preview];
		}];
		[preview generatePreviewAsync];

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topIconViewTap:)];
		[preview addGestureRecognizer:g];

		UILongPressGestureRecognizer *swipeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleAppPreviewPan:)];
		swipeGesture.minimumPressDuration = 0.1;
		[preview addGestureRecognizer:swipeGesture];

		preview.userInteractionEnabled = YES;
	}

	if (empty) {
		UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (windowedAppScrollView.frame.size.height - 30) / 2, windowedAppScrollView.frame.size.width, 30)];
		emptyLabel.textAlignment = NSTextAlignmentCenter;
		emptyLabel.font = [UIFont systemFontOfSize:25];
		emptyLabel.text = LOCALIZE(@"NO_APPS", @"Localizable");
		emptyLabel.textColor = [UIColor whiteColor];
		emptyLabel.alpha = 0.7;
		[otherRunningAppsScrollView addSubview:emptyLabel];

		if (otherKillAllButton) {
			[otherKillAllButton removeFromSuperview];
			otherKillAllButton = nil;
		}
	} else {
		if (!otherKillAllButton) {
			otherKillAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[otherKillAllButton setTitle:LOCALIZE(@"KILL_ALL", @"Localizable") forState:UIControlStateNormal];
			otherKillAllButton.titleLabel.font = [UIFont fontWithName:(IS_IOS_OR_NEWER(iOS_9_0) ? @"SFUIText-Medium" : @"HelveticaNeue-Medium") size:14];
			otherKillAllButton.titleLabel.textColor = [UIColor whiteColor];
			[otherKillAllButton sizeToFit];
			otherKillAllButton.frame = CGRectMake(self.frame.size.width - panePadding - otherKillAllButton.frame.size.width, y, otherKillAllButton.frame.size.width, otherKillAllButton.frame.size.height);
			[otherKillAllButton addTarget:self action:@selector(killAllOther) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:otherKillAllButton];
		}
	}

	otherRunningAppsScrollView.contentSize = CGSizeMake(MAX(x, self.frame.size.width + (empty ? 0 : 1)), height * 1.15); // make slightly scrollable
}

- (void)createNewDesktop:(UIButton *)view {
	[[%c(RADesktopManager) sharedInstance] addDesktop:NO];

	[UIView animateWithDuration:0.4 animations:^{
		view.frame = CGRectOffset(view.frame, view.frame.size.width + panePadding, 0);
	} completion:^(BOOL _) {
		[self reloadDesktopSection];
	}];
}

- (void)removeCardForApplication:(SBApplication *)app {
	CGFloat originX = -1;
	UIView *targetView = nil;
	UIScrollView *parentView = [appsWithoutWindows containsObject:app] ? otherRunningAppsScrollView : windowedAppScrollView;
	NSArray *subviews = [parentView.subviews copy];

	for (UIView *view in subviews) {
		if ([view isKindOfClass:[RAMissionControlPreviewView class]]) {
			RAMissionControlPreviewView *real = (RAMissionControlPreviewView *)view;
			if ([real.application.bundleIdentifier isEqualToString:app.bundleIdentifier]) {
				originX = view.frame.origin.x;
				targetView = view;
			}
		}

		if (originX == -1) {
			continue;
		} else if (view.frame.origin.x == originX) {
			[UIView animateWithDuration:0.2 animations:^{
				view.frame = CGRectOffset(view.frame, 0, view.frame.size.height + panePadding);
			} completion:^(BOOL _) {
				[view removeFromSuperview];
			}];
		} else if (view.frame.origin.x > originX) {
			[UIView animateWithDuration:0.4 animations:^{
				view.frame = CGRectOffset(view.frame, -view.frame.size.width - panePadding, 0);
			}];
		}
	}

	if (parentView.contentSize.width - 1 <= self.frame.size.width) {
		; // don't make it too small to scroll
	} else if (targetView) {
		parentView.contentSize = CGSizeMake(parentView.contentSize.width - targetView.frame.size.width - panePadding + 1, parentView.contentSize.height);
	}
}

- (void)handleAppPreviewPan:(UILongPressGestureRecognizer *)gesture {
	static CGPoint initialCenter;
	static UIView *draggedView;
	static CGPoint lastPoint;

	CGPoint point = [gesture locationInView:self];

	if (gesture.state == UIGestureRecognizerStateBegan) {
		if (!trashImageView || !trashImageView.superview /* new window perhaps */) {
			trashImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width / 2) - (75/2), self.frame.size.height + 75, 75, 75)];
			trashImageView.image = trashIcon;
			[self addSubview:trashImageView];

			shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 75)];
			shadowView.backgroundColor = [UIColor blackColor];
			shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
			shadowView.layer.shadowRadius = 75/2;
		    shadowView.layer.shadowOpacity = 0.9;
		    shadowView.layer.shadowOffset = CGSizeMake(0, -((75 / 2)));
		    shadowView.alpha = 0;
		    [self addSubview:shadowView];
		}
		[UIView animateWithDuration:0.4 animations:^{
			shadowView.alpha = 1;
			trashImageView.alpha = 1;
			trashImageView.frame = CGRectMake((self.frame.size.width / 2) - (75 / 2), self.frame.size.height - (75 + 45), 75, 75);
		}];

		if (!draggedView) {
			draggedView = [gesture.view snapshotViewAfterScreenUpdates:YES];
			draggedView.frame = gesture.view.frame;
			draggedView.center = [gesture.view.superview convertPoint:gesture.view.center toView:self];

			[self addSubview:draggedView];
			gesture.view.alpha = 0.6;

			[UIView animateWithDuration:0.3 animations:^{
				draggedView.transform = CGAffineTransformMakeScale(1.1, 1.1);
			}];
		}
		initialCenter = draggedView.center;
	} else if (gesture.state == UIGestureRecognizerStateChanged) {
		//CGPoint newCenter = [gesture translationInView:draggedView];
		//newCenter.x += initialCenter.x;
		//newCenter.y += initialCenter.y;
		//draggedView.center = newCenter;

		CGPoint center = draggedView.center;
		center.x += point.x - lastPoint.x;
		center.y += point.y - lastPoint.y;
		draggedView.center = center;
	} else {
		gesture.view.alpha = 1;

		//CGPoint center = [gesture translationInView:draggedView];
		//center.x += initialCenter.x;
		//center.y += initialCenter.y;
		CGPoint center = draggedView.center;
		center.x += point.x - lastPoint.x;
		center.y += point.y - lastPoint.y;

		BOOL didKill = NO;

		if (CGRectContainsPoint(trashImageView.frame, center) || CGRectContainsPoint(CGRectOffset(shadowView.frame, 0, -(75 / 2)), center)) {
			SBApplication *app = ((RAMissionControlPreviewView *)gesture.view).application;
			[[%c(RADesktopManager) sharedInstance] removeAppWithIdentifier:app.bundleIdentifier animated:NO];
			[[%c(RAWindowStatePreservationSystemManager) sharedInstance] removeWindowInformationForIdentifier:app.bundleIdentifier];
			if ([[RASettings sharedInstance] missionControlKillApps]) {
				[RAAppKiller killAppWithSBApplication:app completion:^{

					dispatch_async(dispatch_get_main_queue(), ^{
						[self reloadDesktopSection];
					});
					//[self.manager inhibitApplication:app.bundleIdentifier];
					//[self performSelectorOnMainThread:@selector(reloadWindowedAppsSection) withObject:nil waitUntilDone:YES];
					//[self performSelectorOnMainThread:@selector(reloadOtherAppsSection) withObject:nil waitUntilDone:YES];
					//dispatch_async(dispatch_get_main_queue(), ^{
					//	[self removeCardForApplication:app];
					//});
				}];
			}

			didKill = YES;
		}
		[UIView animateWithDuration:0.4 animations:^{
			shadowView.alpha = 0;
			trashImageView.alpha = 0;
			trashImageView.frame = CGRectMake((self.frame.size.width / 2) - (75/2), self.frame.size.height + 75, 75, 75);
		} completion:nil];

		if (!didKill) {
			for (UIView *subview in desktopScrollView.subviews) {
				if (![subview isKindOfClass:[RAMissionControlPreviewView class]]) {
					continue;
				}
				if (CGRectContainsPoint((CGRect){ [desktopScrollView convertPoint:subview.frame.origin toView:self], subview.frame.size }, center) || (CGRectContainsPoint((CGRect){ [windowedAppScrollView convertPoint:subview.frame.origin toView:self], windowedAppScrollView.frame.size }, center) && gesture.view.superview != windowedAppScrollView)) {
					RADesktopWindow *desktop = [[%c(RADesktopManager) sharedInstance] desktopAtIndex:subview.tag];
					SBApplication *app = ((RAMissionControlPreviewView *)gesture.view).application;

					[[[%c(RADesktopManager) sharedInstance] currentDesktop] removeAppWithIdentifier:app.bundleIdentifier animated:NO];

					[desktop createAppWindowForSBApplication:app animated:NO];

					[[RASnapshotProvider sharedInstance] forceReloadSnapshotOfDesktop:[[%c(RADesktopManager) sharedInstance] currentDesktop]];
					[[RASnapshotProvider sharedInstance] forceReloadSnapshotOfDesktop:desktop];

					[self reloadDesktopSection];
					[self reloadWindowedAppsSection];
					[self reloadOtherAppsSection];
				}
			}
		}

		[UIView animateWithDuration:0.4 animations:^{
			if (!didKill) {
				draggedView.transform = CGAffineTransformIdentity;
				draggedView.center = initialCenter;
			}
		} completion:^(BOOL _) {
			[draggedView removeFromSuperview];
			draggedView = nil;
		}];
	}
	lastPoint = point;
}

- (void)animateDesktopRemovalForDesktopAtIndexReloadingSectionAfter:(NSInteger)index {
	CGFloat originX = -1;
	for (UIView *v in desktopScrollView.subviews) {
		if (v.tag == index) {
			originX = v.frame.origin.x;
			[UIView animateWithDuration:0.2 animations:^{
				v.frame = CGRectOffset(v.frame, 0, -panePadding);
			} completion:^(BOOL _) {
				[v removeFromSuperview];
			}];
		} else if (v.tag > index || (originX != -1 && originX < v.frame.origin.x)) {
			[UIView animateWithDuration:0.4 animations:^{
				v.frame = CGRectOffset(v.frame, -v.frame.size.width - panePadding, 0);
			}];
		}
	}
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self reloadDesktopSection];
	});
}

- (void)handleDesktopPan:(UIPanGestureRecognizer *)gesture {
	static CGPoint initialCenter;

	if (gesture.state == UIGestureRecognizerStateBegan) {
		initialCenter = gesture.view.center;
	} else if (gesture.state == UIGestureRecognizerStateChanged) {
		CGPoint newCenter = [gesture translationInView:gesture.view];
		//newCenter.x += initialCenter.x;
		newCenter.x = initialCenter.x;
		if (newCenter.y > 0 || gesture.view.tag == 0) {
			newCenter.y = initialCenter.y + (newCenter.y / 5); //initialCenter.y;
		} else {
			newCenter.y += initialCenter.y;
		}

		gesture.view.center = newCenter;
	} else {
		if (gesture.view.center.y - initialCenter.y < -80 && gesture.view.tag > 0) {
			[[%c(RADesktopManager) sharedInstance] removeDesktopAtIndex:gesture.view.tag];
			[UIView animateWithDuration:0.4 animations:^{
				gesture.view.center = CGPointMake(gesture.view.center.x, -gesture.view.frame.size.height);
			} completion:^(BOOL _) {
				[self animateDesktopRemovalForDesktopAtIndexReloadingSectionAfter:gesture.view.tag];
			}];
		} else {
			[UIView animateWithDuration:0.4 animations:^{
				gesture.view.center = initialCenter;
			}];
		}
	}
}

- (void)activateDesktop:(UITapGestureRecognizer *)gesture {
	NSInteger desktop = gesture.view.tag;
	[[%c(RADesktopManager) sharedInstance] switchToDesktop:desktop];
	[self.manager hideMissionControl:YES];
}

- (void)handleSingleDesktopTap:(UITapGestureRecognizer *)gesture {
	NSInteger desktop = gesture.view.tag;
	[[%c(RADesktopManager) sharedInstance] switchToDesktop:desktop actuallyShow:NO];
	[self reloadDesktopSection];
	[self reloadWindowedAppsSection];
	[self reloadOtherAppsSection];
}

- (void)handleDoubleDesktopTap:(UITapGestureRecognizer *)gesture {
	[self activateDesktop:gesture];
}

- (void)topIconViewTap:(UITapGestureRecognizer*)gesture {
	[self.manager hideMissionControl:YES];
	__block __strong NSString *identifier = [[[gesture view] performSelector:@selector(application)] bundleIdentifier];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:identifier suspended:NO];
		identifier = nil;
	});
}

- (void)killAllWindowed {
	for (UIView *view in windowedAppScrollView.subviews) {
		if (![view isKindOfClass:[RAMissionControlPreviewView class]]) {
			continue;
		}
		RAMissionControlPreviewView *realView = (RAMissionControlPreviewView *)view;
		SBApplication *app = realView.application;
		[RAAppKiller killAppWithSBApplication:app completion:^{
			[self performSelectorOnMainThread:@selector(reloadWindowedAppsSection) withObject:nil waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(reloadOtherAppsSection) withObject:nil waitUntilDone:YES];
		}];
	}
}

- (void)killAllOther {
	for (UIView *view in otherRunningAppsScrollView.subviews) {
		if (![view isKindOfClass:[RAMissionControlPreviewView class]]) {
			continue;
		}
		RAMissionControlPreviewView *realView = (RAMissionControlPreviewView *)view;
		SBApplication *app = realView.application;
		[RAAppKiller killAppWithSBApplication:app completion:^{
			[self performSelectorOnMainThread:@selector(reloadWindowedAppsSection) withObject:nil waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(reloadOtherAppsSection) withObject:nil waitUntilDone:YES];
		}];
	}
}

- (void)applicationDidLaunch:(NSString *)bundleIdentifier {
	[self reloadWindowedAppsSection];
	[self reloadOtherAppsSection];
}

- (void)applicationDidExit:(NSString *)bundleIdentifier {
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
	[self removeCardForApplication:app];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	NSEnumerator *objects = [self.subviews reverseObjectEnumerator];
	UIView *subview;
	while ((subview = [objects nextObject])) {
		UIView *success = [subview hitTest:[self convertPoint:point toView:subview] withEvent:event];
		if (success) {
			return success;
		}
	}
	return self;
	//return [super hitTest:point withEvent:event];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	if (CGRectContainsPoint(self.frame, point)) {
		return YES;
	}

	return [super pointInside:point withEvent:event];
}
@end