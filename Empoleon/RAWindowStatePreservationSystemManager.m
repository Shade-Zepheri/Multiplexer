#import "RAWindowStatePreservationSystemManager.h"
#import "RADesktopManager.h"
#import "RAHostedAppView.h"

static NSString * const RAPreservedWindowStatePath = @"/User/Library/Preferences/com.efrederickson.empoleon.windowstates.plist";

@implementation RAPreservedDesktopInformation

- (instancetype)initWithIndex:(NSUInteger)index {
	self = [super init];
	if (self) {
		self.index = index;
	}

	return self;
}

@end

@implementation RAWindowStatePreservationSystemManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RAWindowStatePreservationSystemManager, [sharedInstance loadInfo]);
}

- (void)loadInfo {
	dict = [NSMutableDictionary dictionaryWithContentsOfFile:RAPreservedWindowStatePath] ?: [NSMutableDictionary dictionary];
}

- (void)saveInfo {
	[dict writeToFile:RAPreservedWindowStatePath atomically:YES];
}

- (void)saveDesktopInformation:(RADesktopWindow *)desktop {
	NSUInteger index = [[RADesktopManager sharedInstance].availableDesktops indexOfObject:desktop];
	NSString *key = [NSString stringWithFormat:@"%tu", index];
	NSMutableArray *openApps = [NSMutableArray array];
	for (RAHostedAppView *app in desktop.appViews) {
		[openApps addObject:app.bundleIdentifier];
	}

	dict[key] = openApps;

	[self saveInfo];
}

- (BOOL)hasDesktopInformationAtIndex:(NSInteger)index {
	NSString *key = [NSString stringWithFormat:@"%tu", index];
	return [dict objectForKey:key] != nil;
}

- (RAPreservedDesktopInformation *)desktopInformationForIndex:(NSInteger)index {
	RAPreservedDesktopInformation *info = [[RAPreservedDesktopInformation alloc] initWithIndex:index];
	NSString *key = [NSString stringWithFormat:@"%tu", index];

	NSMutableArray *apps = [NSMutableArray array];
	for (NSString *ident in dict[key]) {
		[apps addObject:ident];
	}

	info.openApps = [apps copy];

	return info;
}

// Window
- (void)saveWindowInformation:(RAWindowBar *)window {
	CGPoint center = window.center;
	CGAffineTransform transform = window.transform;
	NSString *appIdent = window.attachedView.bundleIdentifier;

	dict[appIdent] = @{
		@"center": NSStringFromCGPoint(center),
		@"transform": NSStringFromCGAffineTransform(transform)
	};

	[self saveInfo];
}

- (BOOL)hasWindowInformationForIdentifier:(NSString *)appIdentifier {
	return [dict objectForKey:appIdentifier] != nil;
}

- (RAPreservedWindowInformation)windowInformationForAppIdentifier:(NSString *)identifier {
	RAPreservedWindowInformation info = (RAPreservedWindowInformation) { CGPointZero, CGAffineTransformIdentity };

	NSDictionary *appInfo = dict[identifier];
	if (!appInfo) {
		return info;
	}

	info.center = CGPointFromString(appInfo[@"center"]);
	info.transform = CGAffineTransformFromString(appInfo[@"transform"]);

	return info;
}

- (void)removeWindowInformationForIdentifier:(NSString *)appIdentifier {
	[dict removeObjectForKey:appIdentifier];
	[self saveInfo];
}
@end
