#import "headers.h"
#import <pthread.h>

@protocol RARunningAppsProviderDelegate
@optional
- (void)appDidStart:(SBApplication *)app;
- (void)appDidDie:(SBApplication *)app;
@end

@interface RARunningAppsProvider : NSObject {
	NSMutableArray *apps;
	NSMutableArray *targets;
	pthread_mutex_t mutex;
}
+ (instancetype)sharedInstance;

- (void)addRunningApp:(SBApplication *)app;
- (void)removeRunningApp:(SBApplication *)app;

- (void)addTarget:(__weak NSObject<RARunningAppsProviderDelegate> *)target;
- (void)removeTarget:(__weak NSObject<RARunningAppsProviderDelegate> *)target;

- (NSArray *)runningApplications;
@end
