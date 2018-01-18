#import "headers.h"
#import "RARunningAppsStateProvider.h"

@interface RAAppKiller : NSObject <RARunningAppsStateObserver>
+ (void)killAppWithIdentifier:(NSString *)identifier;
+ (void)killAppWithIdentifier:(NSString *)identifier completion:(void(^)())handler;
+ (void)killAppWithSBApplication:(SBApplication *)app;
+ (void)killAppWithSBApplication:(SBApplication *)app completion:(void(^)())handler;
@end
