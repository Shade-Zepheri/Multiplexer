#import "headers.h"

@interface RAHostManager : NSObject
+ (FBSceneLayerHostContainerView *)systemHostViewForApplication:(SBApplication *)app;
+ (FBSceneHostWrapperView *)enabledHostViewForApplication:(SBApplication *)app;
+ (FBSceneHostManager *)hostManagerForApp:(SBApplication *)app;
@end
