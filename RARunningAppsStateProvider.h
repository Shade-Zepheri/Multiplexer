#import "headers.h"

@protocol RARunningAppsStateObserver <NSObject>
@optional

- (void)applicationDidLaunch:( NSString *)bundleIdentifier;
- (void)applicationDidExit:(NSString *)bundleIdentifier;

@end

typedef void (^RARunningAppsStateObserverHandler)(id<RARunningAppsStateObserver> observer);

@interface RARunningAppsStateProvider : NSObject {
    NSHashTable *_observers;
    dispatch_queue_t _queue;
    dispatch_queue_t _callOutQueue;
}

@property (copy, readonly, nonatomic) NSArray *runningApps;

+ (instancetype)defaultStateProvider;

- (void)addObserver:(id<RARunningAppsStateObserver>)observer;
- (void)removeObserver:(id<RARunningAppsStateObserver>)observer;

@end
