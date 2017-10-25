#import "RASwipeOverOverlay.h"
#import "RASwipeOverManager.h"

@implementation RASwipeOverOverlay
@synthesize grabberView;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		//self.backgroundColor = [UIColor blueColor];
		//self.alpha = 0.4;
		self.windowLevel = UIWindowLevelStatusBar + 1;

		UIPanGestureRecognizer *g = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		g.delegate = self;
		[self addGestureRecognizer:g];

		UILongPressGestureRecognizer *g2 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
		g2.delegate = self;
		[self addGestureRecognizer:g2];

		CGFloat knobWidth = 10;
		CGFloat knobHeight = 30;
		grabberView = [[UIView alloc] initWithFrame:CGRectMake(2, (self.frame.size.height / 2) - (knobHeight / 2), knobWidth - 4, knobHeight)];
		grabberView.alpha = 0.5;
		grabberView.layer.cornerRadius = knobWidth / 2;
		grabberView.backgroundColor = [UIColor whiteColor];
		[self addSubview:grabberView];
	}

	return self;
}

- (void)showEnoughToDarkenUnderlyingApp {
	if (self.hidingUnderlyingApp) {
		return;
	}
	_hidingUnderlyingApp = YES;

	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
	darkenerView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	darkenerView.frame = self.frame;
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(darkenerViewTap:)];
	[darkenerView addGestureRecognizer:tap];
	[self addSubview:darkenerView];
	grabberView.hidden = YES;
}

- (void)removeOverlayFromUnderlyingApp {
	if (!self.hidingUnderlyingApp) {
		return;
	}
	_hidingUnderlyingApp = NO;

	[UIView animateWithDuration:0.3 animations:^{
		darkenerView.alpha = 0;
	} completion:^(BOOL _) {
		grabberView.hidden = NO;
		[darkenerView removeFromSuperview];
		darkenerView = nil;
	}];
}

- (void)removeOverlayFromUnderlyingAppImmediately {
	if (!self.hidingUnderlyingApp) {
		return;
	}
	_hidingUnderlyingApp = NO;

	[darkenerView removeFromSuperview];
	darkenerView = nil;
}

- (void)showAppSelector {
	[self longPress:nil];
}

- (UIView *)currentView {
	return [self viewWithTag:SwipeOverViewTag];
}

- (BOOL)isShowingAppSelector {
	return [self.currentView isKindOfClass:[RAAppSelectorView class]];
}

- (void)darkenerViewTap:(UITapGestureRecognizer *)gesture {
	[[RASwipeOverManager sharedInstance] convertSwipeOverViewToSideBySide];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
	CGPoint newPoint = [gesture translationInView:gesture.view];
	[[RASwipeOverManager sharedInstance] sizeViewForTranslation:newPoint state:gesture.state];
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture {
	[[RASwipeOverManager sharedInstance] closeCurrentView];
	if ([[self currentView] isKindOfClass:[RAAppSelectorView class]]) {
		[(RAAppSelectorView *)[self currentView] relayoutApps];
		[self currentView].frame = CGRectMake(self.hidingUnderlyingApp ? 0 : 10, 0, self.frame.size.width - (self.hidingUnderlyingApp ? 0 : 10), self.frame.size.height);
		return;
	}

	RAAppSelectorView *appSelector = [[RAAppSelectorView alloc] initWithFrame:CGRectMake(self.hidingUnderlyingApp ? 0 : 10, 0, self.frame.size.width - (self.hidingUnderlyingApp ? 0 : 10), self.frame.size.height)];
	appSelector.tag = SwipeOverViewTag;
	appSelector.target = self;
	[appSelector relayoutApps];
	[self addSubview:appSelector];
}

- (void)appSelector:(RAAppSelectorView *)view appWasSelected:(NSString *)bundleIdentifier {
	grabberView.alpha = 1;
	[self.currentView removeFromSuperview];
	[[RASwipeOverManager sharedInstance] showApp:bundleIdentifier];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	UIView *v = [self viewWithTag:SwipeOverViewTag];
	if ([v isKindOfClass:[RAAppSelectorView class]]) {
		return NO;
	}
	if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
		return NO;
	}
	return YES;
}
@end
