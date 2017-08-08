#import "headers.h"
#import <pthread.h>

@protocol RARunningAppsProviderDelegate
@optional
- (void)appDidStart:(SBApplication *)app;
- (void)appDidDie:(SBApplication *)app;
@end

@interface RARunningAppsProvider : NSObject {
	pthread_mutex_t mutex;
}
@property (strong, nonatomic) NSMutableArray *runningApps;
@property (strong, nonatomic) NSMutableArray *targets;

+ (instancetype)sharedInstance;

- (void)addRunningApp:(SBApplication *)app;
- (void)removeRunningApp:(SBApplication *)app;

- (void)addTarget:(__weak NSObject<RARunningAppsProviderDelegate> *)target;
- (void)removeTarget:(__weak NSObject<RARunningAppsProviderDelegate> *)target;

@end
