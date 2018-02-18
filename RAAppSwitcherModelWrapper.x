#import "RAAppSwitcherModelWrapper.h"

@implementation RAAppSwitcherModelWrapper

+ (void)addToFront:(SBApplication *)app {
  [self.class addIdentifierToFront:app.bundleIdentifier];
}

+ (void)addIdentifierToFront:(NSString *)displayIdentifier {
  SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
  SBDisplayItem *layout = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:displayIdentifier];
  if ([layout respondsToSelector:@selector(addToFront:)]) {
    [model addToFront:layout];
  } else {
    [model addToFront:layout role:2];
  }
}

+ (NSArray *)appSwitcherAppIdentiferList {
  SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
  if ([model respondsToSelector:@selector(mainSwitcherDisplayItems)]) {
    NSMutableArray *ret = [NSMutableArray array];
    NSArray *list = [model mainSwitcherDisplayItems];
    for (SBDisplayItem *item in list) {
      [ret addObject:item.displayIdentifier];
    }

    return ret;
  } else {
    SBRecentAppLayouts *recents = [%c(SBRecentAppLayouts) sharedInstance];
    return [recents recents];
  }
}

+ (void)removeItemWithIdentifier:(NSString *)ident {
	SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:ident];
	[[%c(SBAppSwitcherModel) sharedInstance] remove:item];
}

@end
