#import "RARunningAppsStateProvider.h"

@implementation RARunningAppsStateProvider

+ (instancetype)defaultStateProvider {
	SHARED_INSTANCE(RARunningAppsStateProvider);
}

- (instancetype)init {
	self = [super init];
	if (self) {
		//This whole class is rather overkill but hey (Pretty much copies FBProcessManager)
		_observers = [[NSHashTable alloc] initWithOptions:(NSHashTableObjectPointerPersonality | NSHashTableWeakMemory) capacity:1];

		//create queues
		dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_autorelease_frequency(nil, DISPATCH_AUTORELEASE_FREQUENCY_NEVER);
		dispatch_queue_attr_t mainAttributes = dispatch_queue_attr_make_with_qos_class(attributes, 0x19, 0);
		_queue = dispatch_queue_create("com.efrederickson.reachapp.runningapps-provider", mainAttributes);

		dispatch_queue_attr_t calloutAttributes = dispatch_queue_attr_make_with_qos_class(attributes, 0x21, 0);
		_callOutQueue = dispatch_queue_create("com.efrederickson.reachapp.runningapps-provider.call-out", calloutAttributes);
	}

	return self;
}

- (NSArray *)runningApps {
	return [[%c(SBApplicationController) sharedInstance] runningApplications];
}

- (void)addObserver:(id<RARunningAppsStateObserver>)observer {
	dispatch_sync(_queue, ^{
		if ([_observers containsObject:observer]) {
		  return;
		}

    [_observers addObject:observer];
	});
}

- (void)removeObserver:(id<RARunningAppsStateObserver>)observer {
	dispatch_sync(_queue, ^{
		if (![_observers containsObject:observer]) {
			return;
		}

    [_observers removeObject:observer];
	});
}

- (void)notifyObserversUsingBlock:(RARunningAppsStateObserverHandler)handler {
	//Dispatch on calloutQueue
	dispatch_async(_callOutQueue, ^{
		__block NSArray *observers;

		dispatch_sync(_queue, ^{
			observers = [_observers.allObjects copy];
		});

		for (id<RARunningAppsStateObserver> observer in observers) {
			dispatch_async(_queue, ^{
				handler(observer);
			});
		}
	});
}

@end

%hook SBMainWorkspace

- (void)process:(FBProcess *)process stateDidChangeFromState:(FBProcessState *)fromState toState:(FBProcessState *)toState {
  %orig;

  BOOL isRunning = toState.running;
  NSString *bundleIdentifier = process.bundleIdentifier;

  RARunningAppsStateObserverHandler handlerBlock = ^(id<RARunningAppsStateObserver> observer) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (isRunning && [observer respondsToSelector:@selector(applicationDidLaunch:)]) {
        [observer applicationDidLaunch:bundleIdentifier];
      } else if (!isRunning && [observer respondsToSelector:@selector(applicationDidExit:)]) {
        [observer applicationDidExit:bundleIdentifier];
      }
    });
  };

  [[RARunningAppsStateProvider defaultStateProvider] notifyObserversUsingBlock:handlerBlock];
}

%end
