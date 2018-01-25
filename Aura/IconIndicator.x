#import "ColorBadges.h"
#import "RABackgrounder.h"
#import "RASettings.h"
#import "RAAppIconStatusBarIconView.h"
#import <libstatusbar/LSStatusBarItem.h>
#import <libstatusbar/UIStatusBarCustomItem.h>

//TODO: Better method of doing this
NSMutableDictionary *indicatorStateDict;
#define SET_INFO_(x, y)    indicatorStateDict[x] = @(y)
#define GET_INFO_(x)       [indicatorStateDict[x] intValue]
#define SET_INFO(y)        if (self.icon && self.icon.application) SET_INFO_(self.icon.application.bundleIdentifier, y);
#define GET_INFO           (self.icon && self.icon.application ? GET_INFO_(self.icon.application.bundleIdentifier) : RAIconIndicatorViewInfoNone)


NSString *stringFromIndicatorInfo(RAIconIndicatorViewInfo info) {
	NSString *ret = @"";

	if (info & RAIconIndicatorViewInfoNone) {
		return nil;
	}

	if ([[RASettings sharedInstance] showNativeStateIconIndicators] && (info & RAIconIndicatorViewInfoNative)) {
		ret = [ret stringByAppendingString:@"N"];
	}

	if (info & RAIconIndicatorViewInfoForced) {
		ret = [ret stringByAppendingString:@"F"];
	}

	//if (info & RAIconIndicatorViewInfoForceDeath)
	//	[ret appendString:@"D"];

	if (info & RAIconIndicatorViewInfoSuspendImmediately) {
		ret = [ret stringByAppendingString:@"ll"];
	}

	if (info & RAIconIndicatorViewInfoUnkillable) {
		ret = [ret stringByAppendingString:@"U"];
	}

	if (info & RAIconIndicatorViewInfoUnlimitedBackgroundTime) {
		ret = [ret stringByAppendingString:@"∞"];
	}

	return ret;
}

%hook SBIconView
%property (retain, nonatomic) SBIconBadgeView *_ra_badgeView;

%new - (CGRect)_ra_frameForAccessoryView:(SBIconBadgeView *)accessoryView {
	if ([self valueForKey:@"_accessoryView"]) {
		return [self _frameForAccessoryView];
	}

	//implement _frameForAccessoryView manually
	SBIconImageView *imageView = [self valueForKey:@"_iconImageView"];
	CGRect visibleBounds = [imageView visibleBounds];
	CGPoint origin = [accessoryView accessoryOriginForIconBounds:visibleBounds];

	CGPoint actualOrigin = [self convertPoint:origin fromView:imageView];
	return CGRectMake(actualOrigin.x, actualOrigin.y, CGRectGetWidth(accessoryView.frame), CGRectGetHeight(accessoryView.frame));
}

%new - (void)_ra_createCustomBadgeView {
	SBIconBadgeView *badgeView = [[%c(SBIconBadgeView) alloc] init];
	self._ra_badgeView = badgeView;
	//TODO re-add ColorBadges support

	[self addSubview:badgeView];
	[self bringSubviewToFront:badgeView];

	CGAffineTransform transform = CGAffineTransformMakeScale(-1,1);
	badgeView.transform = transform;
}

%new - (void)_ra_updateCustomBadgeView:(RAIconIndicatorViewInfo)info {
	if (![[RASettings sharedInstance] backgrounderEnabled] || ![[RABackgrounder sharedInstance] shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier] || info == RAIconIndicatorViewInfoNone) {
		return;
	}

	if (!self._ra_badgeView) {
		[self _ra_createCustomBadgeView];
	}

	NSString *text = stringFromIndicatorInfo(info);
	[self._ra_badgeView _configureAnimatedForText:text highlighted:NO withPreparation:nil animation:^{
		CGRect frame = [self _ra_frameForAccessoryView:self._ra_badgeView];
		CGFloat width = CGRectGetWidth(self.frame);

		self._ra_badgeView.frame = CGRectMake(CGRectGetMinX(frame) - width, CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
	} completion:nil];

	SET_INFO(info);
}

%new - (void)_ra_updateCustomBadgeWithExitingInfo {
	//if ([self viewWithTag:9962])
	[self _ra_updateCustomBadgeView:GET_INFO];
}

- (void)setIsEditing:(BOOL)editing animated:(BOOL)animated {
	%orig;

	// inhibit icon indicator
	self._ra_badgeView.hidden = editing;
}

%end

NSMutableDictionary *lsbitems;

%hook SBApplication
%new - (void)RA_addStatusBarIconForSelfIfOneDoesNotExist {
#if DEBUG
	if (![lsbitems respondsToSelector:@selector(objectForKey:)]) {
		LogError(@"ERROR: lsbitems is not NSDictionary it is %@", NSStringFromClass([lsbitems class]));
		//@throw [NSException exceptionWithName:@"OH POOP" reason:@"Expected NSDictionary" userInfo:nil];
	}
#endif

	if (!%c(LSStatusBarItem) || [lsbitems objectForKey:self.bundleIdentifier] || ![[RABackgrounder sharedInstance] shouldShowStatusBarIconForIdentifier:self.bundleIdentifier]) {
		return;
	}

	SBIconModel *model = [[%c(SBIconController) sharedInstance] valueForKey:@"_iconModel"];
	if (![model.visibleIconIdentifiers containsObject:self.bundleIdentifier]) {
		return;
	}

	RAIconIndicatorViewInfo info = [[RABackgrounder sharedInstance] allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier];
	BOOL native = (info & RAIconIndicatorViewInfoNative);
	if (info == RAIconIndicatorViewInfoNone && (native || ![[RASettings sharedInstance] shouldShowStatusBarNativeIcons])) {
		return;
	}

	LSStatusBarItem *item = [[%c(LSStatusBarItem) alloc] initWithIdentifier:[NSString stringWithFormat:@"multiplexer-%@", self.bundleIdentifier] alignment:StatusBarAlignmentLeft];
	item.imageName = [NSString stringWithFormat:@"multiplexer-%@", self.bundleIdentifier];
	lsbitems[self.bundleIdentifier] = item;
}

- (void)setApplicationState:(NSUInteger)state {
	%orig;

	if (!self.isRunning) {
		[[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
		//SET_INFO_(self.bundleIdentifier, RAIconIndicatorViewInfoNone);
		[lsbitems removeObjectForKey:self.bundleIdentifier];
	} else {
		if ([self respondsToSelector:@selector(RA_addStatusBarIconForSelfIfOneDoesNotExist)]) {
			[self performSelector:@selector(RA_addStatusBarIconForSelfIfOneDoesNotExist)];
		}

		[[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[[RABackgrounder sharedInstance] allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
		SET_INFO_(self.bundleIdentifier, [[RABackgrounder sharedInstance] allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]);
	}
}

%new + (void)RA_clearAllStatusBarIcons {
	[lsbitems removeAllObjects];
}

%end

%hook SBIconViewMap
//Not sure why we have this hook but ok
- (SBIconView *)_iconViewForIcon:(SBIcon *)icon {
	SBIconView *iconView = %orig;

	[iconView _ra_updateCustomBadgeWithExitingInfo];
	return iconView;
}

%end

%group libstatusbar
%hook UIStatusBarCustomItem

- (NSUInteger)leftOrder {
	if ([self.indicatorName hasPrefix:@"multiplexer-"]) {
		return 7; // Shows just after vpn, before the loading/sync indicator
	}

	return %orig;
}

- (Class)viewClass {
	if ([self.indicatorName hasPrefix:@"multiplexer-"]) {
		return %c(RAAppIconStatusBarIconView);
	}

	return %orig;
}

%end
%end

%ctor {
	dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_LAZY);

	lsbitems = [NSMutableDictionary dictionary];
	indicatorStateDict = [NSMutableDictionary dictionary];

	%init;

	if (%c(UIStatusBarCustomItem)) {
		%init(libstatusbar);
	}
}
