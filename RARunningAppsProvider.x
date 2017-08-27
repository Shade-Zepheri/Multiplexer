#import "RARunningAppsProvider.h"

@implementation RARunningAppsProvider
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RARunningAppsProvider,
		sharedInstance.runningApps = [NSMutableArray array];
		sharedInstance.targets = [NSMutableArray array];
	);
}

- (instancetype)init {
	self = [super init];
	if (self) {
		pthread_mutex_init(&mutex, NULL);
	}

	return self;
}

- (void)addRunningApp:(SBApplication *)app {
	pthread_mutex_lock(&mutex);

	[self.runningApps addObject:app];
	for (NSObject<RARunningAppsProviderDelegate>* target in self.targets) {
		if ([target respondsToSelector:@selector(appDidStart:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidStart:app];
			});
		}
	}

	pthread_mutex_unlock(&mutex);
}

- (void)removeRunningApp:(SBApplication *)app {
	pthread_mutex_lock(&mutex);

	[self.runningApps removeObject:app];

	for (NSObject<RARunningAppsProviderDelegate>* target in self.targets) {
		if ([target respondsToSelector:@selector(appDidDie:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidDie:app];
			});
		}
	}

	pthread_mutex_unlock(&mutex);
}

- (void)addTarget:(__weak NSObject<RARunningAppsProviderDelegate> *)target {
	pthread_mutex_lock(&mutex);

	if (![self.targets containsObject:target]) {
		[self.targets addObject:target];
	}

	pthread_mutex_unlock(&mutex);
}

- (void)removeTarget:(__weak NSObject<RARunningAppsProviderDelegate> *)target {
	pthread_mutex_lock(&mutex);

	[self.targets removeObject:target];

	pthread_mutex_unlock(&mutex);
}

- (void)dealloc {
	pthread_mutex_destroy(&mutex);
}

@end

%hook SBApplication
- (void)updateProcessState:(FBProcessState *)state {
	%orig;

	if (state.running && ![[RARunningAppsProvider sharedInstance].runningApps containsObject:self]) {
		[[RARunningAppsProvider sharedInstance] addRunningApp:self];
	} else if (!state.running && [[RARunningAppsProvider sharedInstance].runningApps containsObject:self]) {
		[[RARunningAppsProvider sharedInstance] removeRunningApp:self];
	}
}
%end
