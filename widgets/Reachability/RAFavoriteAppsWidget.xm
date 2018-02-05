#import "headers.h"
#import "RAFavoriteAppsWidget.h"
#import "RAReachabilityManager.h"
#import "RAWidgetSectionManager.h"
#import "RASettings.h"

@interface RAFavoriteAppsWidget () {
	CGFloat savedX;
}
@end

@implementation RAFavoriteAppsWidget
- (BOOL)enabled {
	return [[RASettings sharedInstance] showFavorites];
}

- (NSInteger)sortOrder {
	return 2;
}

- (NSString *)displayName {
	return LOCALIZE(@"FAVORITES", @"Localizable");
}

- (NSString *)identifier {
	return @"com.efrederickson.reachapp.widgets.sections.favoriteapps";
}

- (CGFloat)titleOffset {
	return savedX;
}

- (UIView *)viewForFrame:(CGRect)frame preferredIconSize:(CGSize)size_ iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing {
	CGSize size = [%c(SBIconView) defaultIconSize];
	spacing = (CGRectGetWidth(frame) - (iconsPerLine * size.width)) / iconsPerLine;
	NSString *currentBundleIdentifier = [UIApplication sharedApplication]._accessibilityFrontMostApplication.bundleIdentifier;
	if (!currentBundleIdentifier) {
		return nil;
	}

	CGSize contentSize = CGSizeMake((spacing / 2.0), 10);
	CGFloat interval = (size.width + spacing) * iconsPerLine;
	NSInteger intervalCount = 1;
	BOOL isTop = YES;
	BOOL hasSecondRow = NO;
	CGFloat width = interval;
	savedX = spacing / 2.0;

	NSMutableArray *favorites = [[RASettings sharedInstance] favoriteApps];
	[favorites removeObject:currentBundleIdentifier];
	if (favorites.count == 0) {
		return nil;
	}

	UIScrollView *favoritesView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 200)];
	favoritesView.backgroundColor = [UIColor clearColor];
	favoritesView.pagingEnabled = [[RASettings sharedInstance] pagingEnabled];
	for (NSString *identifier in favorites) {
		@autoreleasepool {
			SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
			SBIconModel *iconModel = [[%c(SBIconController) sharedInstance] valueForKey:@"_iconModel"];
			SBApplicationIcon *icon = [iconModel applicationIconForBundleIdentifier:app.bundleIdentifier];
			SBIconView *iconView = nil;

      if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
				iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
			} else {
				iconView = [[[%c(SBIconController) sharedInstance] homescreenIconViewMap] _iconViewForIcon:icon];
			}

			if (!iconView || ![icon isKindOfClass:%c(SBApplicationIcon)]) {
				continue;
			}

			if (interval != 0 && contentSize.width + CGRectGetWidth(iconView.frame) > interval * intervalCount) {
				if (isTop) {
					contentSize.height += size.height + 10;
					contentSize.width -= interval;
				} else {
					intervalCount++;
					contentSize.height -= (size.height + 10);
					width += interval;
				}
				hasSecondRow = YES;
				isTop = !isTop;
			}

			iconView.frame = CGRectMake(contentSize.width, contentSize.height, CGRectGetWidth(iconView.frame), CGRectGetHeight(iconView.frame));
			iconView.tag = app.pid;
			iconView.restorationIdentifier = app.bundleIdentifier;
			UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
			[iconView addGestureRecognizer:iconViewTapGestureRecognizer];

      LogDebug(@"iconView: %@", iconView);
			[favoritesView addSubview:iconView];

			contentSize.width += CGRectGetWidth(iconView.frame) + spacing;
		}
	}

	contentSize.width = width;
	contentSize.height = 10 + ((size.height + 10) * (hasSecondRow ? 2 : 1));
	frame = favoritesView.frame;
	frame.size.height = contentSize.height;
	favoritesView.frame = frame;
	favoritesView.contentSize = contentSize;
	return favoritesView;
}

- (void)appViewItemTap:(UIGestureRecognizer *)gesture {
	[GET_SBWORKSPACE appViewItemTap:gesture];
	//[[RAReachabilityManager sharedInstance] launchTopAppWithIdentifier:gesture.view.restorationIdentifier];
}
@end

%ctor {
	static id _widget = [[RAFavoriteAppsWidget alloc] init];
	[[RAWidgetSectionManager sharedInstance] registerSection:_widget];
}
