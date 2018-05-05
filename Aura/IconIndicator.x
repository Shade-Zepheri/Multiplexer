#import "ColorBadges.h"
#import "RABackgrounder.h"
#import "RASettings.h"
#import "RAAppIconStatusBarIconView.h"
#import "SBApplication+Aura.h"
#import "SBIconView+Aura.h"
#import <libstatusbar/LSStatusBarItem.h>
#import <libstatusbar/UIStatusBarCustomItem.h>

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

%new - (void)_ra_createCustomBadgeViewIfNecessary {
    if (self._ra_badgeView) {
        //Find way to recycle view?
        return;
    }

    SBIconBadgeView *badgeView = [[%c(SBIconBadgeView) alloc] init];
    self._ra_badgeView = badgeView;

    [self addSubview:badgeView];
    [self bringSubviewToFront:badgeView];

    CGAffineTransform transform = CGAffineTransformMakeScale(-1,1);
    badgeView.transform = transform;
}

%new - (void)_ra_updateCustomBadgeWithInfo:(RAIconIndicatorViewInfo)info {
    if (![[RASettings sharedInstance] backgrounderEnabled] || ![[RABackgrounder sharedInstance] shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) {
        return;
    }

    if (info == RAIconIndicatorViewInfoNone) {
        if (self._ra_badgeView) {
            [self._ra_badgeView removeFromSuperview];
            self._ra_badgeView = nil;
        }

        return;
    }

    [self _ra_createCustomBadgeViewIfNecessary];

    // For ColorBadges
    if ([self._ra_badgeView respondsToSelector:@selector(configureForIcon:infoProvider:)]) {
        [self._ra_badgeView configureForIcon:self.icon infoProvider:self]; // iOS 11; TODO: i think those are the right args
    } else {
        [self._ra_badgeView configureForIcon:self.icon location:self.location highlighted:NO];
    }

    NSString *text = stringFromIndicatorInfo(info);
    [self._ra_badgeView _configureAnimatedForText:text highlighted:NO withPreparation:nil animation:^{
        CGRect frame = [self _ra_frameForAccessoryView:self._ra_badgeView];
        CGFloat width = CGRectGetWidth(self.frame);

        self._ra_badgeView.frame = CGRectMake(CGRectGetMinX(frame) - width, CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
    } completion:nil];
}

%new - (void)_ra_updateCustomBadge {
    if (![self.icon isApplicationIcon]) {
        return;
    }

    RAIconIndicatorViewInfo info = [[self.icon application] _ra_iconIndicatorInfo];
	[self _ra_updateCustomBadgeWithInfo:info];
}

- (void)_updateAccessoryViewWithAnimation:(BOOL)animated {
    %orig;

    [self _ra_updateCustomBadge];
}

- (void)_updateBrightness {
    %orig;

    // Dim badge when tapped
    SBIconImageView *imageView = [self valueForKey:@"_iconImageView"];
    CGFloat brightness = imageView.brightness;
    [self._ra_badgeView setAccessoryBrightness:brightness];
}

- (void)_applyIconAccessoryAlpha:(CGFloat)alpha {
    %orig;

    //So it disappears when app launched
    self._ra_badgeView.alpha = alpha;
}

- (void)setIsEditing:(BOOL)editing animated:(BOOL)animated {
    %orig;

    // Hide icon when editing
    self._ra_badgeView.hidden = editing;
}

%end

NSMutableDictionary *lsbitems;

%hook SBApplication
%property (retain, nonatomic) NSMutableDictionary *_ra_indicatorInfo;

%new - (void)_ra_addStatusBarIconIfNecessary {
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

// Gone in iOS 11
- (void)setApplicationState:(NSUInteger)state {
    %orig;

    if (!self.isRunning) {
        //[[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
        //SET_INFO_(self.bundleIdentifier, RAIconIndicatorViewInfoNone);
        [lsbitems removeObjectForKey:self.bundleIdentifier];
    } else {
        if ([self respondsToSelector:@selector(_ra_addStatusBarIconIfNecessary)]) {
            [self _ra_addStatusBarIconIfNecessary];
        }

        //[[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[[RABackgrounder sharedInstance] allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
        RAIconIndicatorViewInfo info = [[RABackgrounder sharedInstance] allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier];
        [self _ra_setIconIndicatorInfo:info];
    }
}

//-(void)_noteProcess:(id)arg1 didChangeToState:(id)arg2

%new - (RAIconIndicatorViewInfo)_ra_iconIndicatorInfo {
    NSMutableDictionary *indicatorInfo = self._ra_indicatorInfo;
    return [indicatorInfo[@"RAIconIndicatorInfo"] intValue];
}

%new - (void)_ra_setIconIndicatorInfo:(RAIconIndicatorViewInfo)info {
    self._ra_indicatorInfo[@"RAIconIndicatorInfo"] = @(info);
}

%new + (void)RA_clearAllStatusBarIcons {
	[lsbitems removeAllObjects];
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

	%init;

	if (%c(UIStatusBarCustomItem)) {
		%init(libstatusbar);
	}
}
