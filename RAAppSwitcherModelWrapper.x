#import "RAAppSwitcherModelWrapper.h"

@implementation RAAppSwitcherModelWrapper
+ (void)addToFront:(SBApplication *)app {
	SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
	SBDisplayItem *layout = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:app.bundleIdentifier];
	[model addToFront:layout role:2];
}

+ (void)addIdentifierToFront:(NSString *)ident {
	[RAAppSwitcherModelWrapper addToFront:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:ident]];
}

+ (NSArray *)appSwitcherAppIdentiferList {
	SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];

	NSMutableArray *ret = [NSMutableArray array];
	NSArray *list = [model mainSwitcherDisplayItems]; // NSArray<SBDisplayItem>
	for (SBDisplayItem *item in list) {
		[ret addObject:item.displayIdentifier];
	}

	return ret;
}

+ (void)removeItemWithIdentifier:(NSString *)ident {
	SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:ident];
	SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
	[model remove:item];
}
@end
