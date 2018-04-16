#import "RAThemeManager.h"
#import "RAThemeLoader.h"
#import "RASettings.h"
#import "headers.h"

@implementation RAThemeManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RAThemeManager, [sharedInstance invalidateCurrentThemeAndReload:nil]); // will be reloaded by RASettings
}

- (NSArray *)allThemes {
	return allThemes.allValues;
}

- (void)invalidateCurrentThemeAndReload:(NSString *)currentIdentifier {
#if DEBUG
	LogDebug(@"[ReachApp] loading themes...");
	NSDate *startTime = [NSDate date];
#endif


	_currentTheme = nil;
	[allThemes removeAllObjects];
	allThemes = [NSMutableDictionary dictionary];

	NSString *folderName = [NSString stringWithFormat:@"%@/Themes/", MultiplexerBasePath];
	NSArray *themeFileNames = [[NSFileManager defaultManager] subpathsAtPath:folderName];

	for (NSString *themeName in themeFileNames) {
		if (![themeName hasSuffix:@"plist"]) {
			continue;
		}

		RATheme *theme = [RAThemeLoader loadFromFile:themeName];
		if (theme && theme.themeIdentifier) {
			//LogDebug(@"[ReachApp] adding %@", theme.themeIdentifier);
			allThemes[theme.themeIdentifier] = theme;

			if ([theme.themeIdentifier isEqualToString:currentIdentifier]) {
				_currentTheme = theme;
			}
		}
	}
	if (!_currentTheme) {
		_currentTheme = [allThemes objectForKey:@"com.eljahandandrew.multiplexer.themes.default"];
		if (!_currentTheme && allThemes.allKeys.count > 0) {
			_currentTheme = allThemes[allThemes.allKeys[0]];
		}
	}

#if DEBUG
	LogDebug(@"[ReachApp] loaded %tu themes in %f seconds.", allThemes.count, fabs([startTime timeIntervalSinceNow]));
#endif
}
@end
