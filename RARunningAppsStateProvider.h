#import "headers.h"

@protocol RARunningAppsStateObserver
@optional
- (void)applicationDidLaunch:( NSString *)bundleIdentifier;
- (void)applicationDidExit:(NSString *)bundleIdentifier;
@end

typedef void (^RARunningAppsStateObserverHandler)(NSObject<RARunningAppsStateObserver> *observer);

@interface RARunningAppsStateProvider : NSObject {
    NSHashTable *_observers;
    dispatch_queue_t _queue;
    dispatch_queue_t _callOutQueue;
}

@property (copy, readonly, nonatomic) NSArray *runningApps;

+ (instancetype)defaultStateProvider;

- (void)addObserver:(__weak NSObject<RARunningAppsStateObserver> *)observer;
- (void)removeObserver:(__weak NSObject<RARunningAppsStateObserver> *)observer;

@end
