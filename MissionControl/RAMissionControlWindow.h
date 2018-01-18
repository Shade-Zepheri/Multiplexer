#import "headers.h"
#import "RARunningAppsStateProvider.h"

@class RAMissionControlManager;

@interface RAMissionControlWindow : UIAutoRotatingWindow  <RARunningAppsStateObserver>
@property (nonatomic, weak) RAMissionControlManager *manager;

- (void)reloadDesktopSection;
- (void)reloadWindowedAppsSection;
- (void)reloadWindowedAppsSection:(NSArray *)runningApplications;
- (void)reloadOtherAppsSection;
@end
