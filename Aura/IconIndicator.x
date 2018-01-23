#import "ColorBadges.h"
#import "RABackgrounder.h"
#import "RASettings.h"
#import "RAAppIconStatusBarIconView.h"
#import <Anemone/ANEMSettingsManager.h>
#import <libstatusbar/LSStatusBarItem.h>
#import <libstatusbar/UIStatusBarCustomItem.h>

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
%property (nonatomic, assign) BOOL RA_isIconIndicatorInhibited;
%new - (void)RA_updateIndicatorView:(RAIconIndicatorViewInfo)info {
	if (info == RAIconIndicatorViewInfoTemporarilyInhibit || info == RAIconIndicatorViewInfoInhibit) {
		[[self viewWithTag:9962] removeFromSuperview];
		[self RA_setIsIconIndicatorInhibited:YES];
		if (info == RAIconIndicatorViewInfoTemporarilyInhibit) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[self RA_setIsIconIndicatorInhibited:NO showAgainImmediately:NO];
			});
		}
		return;
	} else if (info == RAIconIndicatorViewInfoUninhibit) {
		[self RA_setIsIconIndicatorInhibited:NO showAgainImmediately:NO];
	}

	NSString *text = stringFromIndicatorInfo(info);

	if (self.RA_isIconIndicatorInhibited ||
		(!text || text.length == 0) || // OR info == RAIconIndicatorViewInfoNone
		(!self.icon || !self.icon.application || !self.icon.application.isRunning || ![[RABackgrounder sharedInstance] shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) ||
		![[RASettings sharedInstance] backgrounderEnabled])
	{
		[[self viewWithTag:9962] removeFromSuperview];
		return;
	}

	UILabel *badge = (UILabel *)[self viewWithTag:9962];
	if (!badge) {
		badge = [[UILabel alloc] init];
		badge.tag = 9962;

		badge.textAlignment = NSTextAlignmentCenter;
		badge.clipsToBounds = YES;
		badge.font = [%c(SBIconBadgeView) _textFont];

		// Note that my macros for this deal with the situation where ColorBadges is not installed
		badge.backgroundColor = GET_COLORBADGES_COLOR(self.icon, THEMED(backgroundingIndicatorBackgroundColor));

		//badge.textColor = GET_ACCEPTABLE_TEXT_COLOR(badge.backgroundColor, THEMED(backgroundingIndicatorTextColor));
		if (HAS_COLORBADGES && [%c(ColorBadges) isEnabled]) {
			int bgColor = RGBFromUIColor(badge.backgroundColor);
			int txtColor = RGBFromUIColor(THEMED(backgroundingIndicatorTextColor));

			if ([%c(ColorBadges) isDarkColor:bgColor]) {
				// dark color
				if ([%c(ColorBadges) isDarkColor:txtColor]) {
					// dark + dark
					badge.textColor = [UIColor whiteColor];
				} else {
					// dark + light
					badge.textColor = THEMED(backgroundingIndicatorTextColor);
				}
			} else {
				// light color
				if ([%c(ColorBadges) isDarkColor:txtColor]) {
					// light + dark
					badge.textColor = THEMED(backgroundingIndicatorTextColor);
				} else {
					//light + light
					badge.textColor = [UIColor blackColor];
				}
			}

			if ([%c(ColorBadges) areBordersEnabled]) {
				badge.layer.borderColor = badge.textColor.CGColor;
				badge.layer.borderWidth = 1.0;
			}
		} else {
			badge.textColor = THEMED(backgroundingIndicatorTextColor);
		}

		UIImage *bgImage = [%c(SBIconBadgeView) _checkoutBackgroundImage];
		if (%c(ANEMSettingsManager) && [[%c(ANEMSettingsManager) sharedManager].themeSettings containsObject:@"ModernBadges"]) {
			badge.backgroundColor = [UIColor colorWithPatternImage:bgImage];
		}

		[self addSubview:badge];

		CGPoint overhang = [%c(SBIconBadgeView) _overhang];
		badge.frame = CGRectMake(-overhang.x, -overhang.y, bgImage.size.width, bgImage.size.height);
		badge.layer.cornerRadius = MAX(badge.frame.size.width, badge.frame.size.height) / 2.0;
	}

	if (%c(ANEMSettingsManager) && [[%c(ANEMSettingsManager) sharedManager].themeSettings containsObject:@"ModernBadges"]) {
		UIImageView *textImageView = (UIImageView *)[badge viewWithTag:42];
		if (!textImageView) {
			CGFloat padding = [%c(SBIconBadgeView) _textPadding];

			textImageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, badge.frame.size.width - (padding * 2.0), badge.frame.size.height - (padding * 2.0))];
			textImageView.center = CGPointMake((badge.frame.size.width / 2.0) + [%c(SBIconBadgeView) _textOffset].x, (badge.frame.size.height / 2.0) + [%c(SBIconBadgeView) _textOffset].y);
			textImageView.tag = 42;
			[badge addSubview:textImageView];
		}

		UIImage *textImage = [%c(SBIconBadgeView) _checkoutImageForText:text highlighted:NO];
		textImageView.image = textImage;
	} else {
		[badge performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:YES];
	}

	SET_INFO(info);
}

%new - (void)RA_updateIndicatorViewWithExistingInfo {
	//if ([self viewWithTag:9962])
	[self RA_updateIndicatorView:GET_INFO];
}

%new - (void)RA_setIsIconIndicatorInhibited:(BOOL)value {
	[self RA_setIsIconIndicatorInhibited:value showAgainImmediately:YES];
}

%new - (void)RA_setIsIconIndicatorInhibited:(BOOL)value showAgainImmediately:(BOOL)value2 {
	self.RA_isIconIndicatorInhibited = value;
	if (value2 || value) {
		[self RA_updateIndicatorViewWithExistingInfo];
	}
}

- (void)dealloc {
	if (self) {
		UIView *view = [self viewWithTag:9962];
		if (view) {
			[view removeFromSuperview];
		}
	}

	%orig;
}

- (void)layoutSubviews {
	%orig;
	//if ([self viewWithTag:9962] == nil)
	// this is back in, again, to try to fix "Smartclose badges show randomly in the app switcher for random applications even though I only have one app smart closed"
	//    [self RA_updateIndicatorView:GET_INFO];
}

- (void)setIsEditing:(BOOL)value animated:(BOOL)animated {
	%orig;

	// inhibit icon indicator
	[self RA_setIsIconIndicatorInhibited:value];
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
	if ((info & RAIconIndicatorViewInfoNone) != 0 || (native || ![[RASettings sharedInstance] shouldShowStatusBarNativeIcons])) {
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

- (void)didAnimateActivation {
	//[[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoUninhibit];
	[[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoTemporarilyInhibit];
	%orig;
}

- (void)willAnimateActivation {
	[[RABackgrounder sharedInstance] updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoInhibit];
	%orig;
}
%end

%hook SBIconViewMap
- (SBIconView *)_iconViewForIcon:(SBIcon *)icon {
	SBIconView *iconView = %orig;

	[iconView RA_updateIndicatorViewWithExistingInfo];
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
