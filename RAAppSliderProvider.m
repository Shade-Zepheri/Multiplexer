#import "RAAppSliderProvider.h"
#import "RAHostedAppView.h"

@interface RAAppSliderProvider () {
	NSCache *cachedViews;
}
@end

@implementation RAAppSliderProvider
@synthesize currentIndex, availableIdentifiers;

- (instancetype)init {
	self = [super init];
	if (self) {
		cachedViews = [[NSCache alloc] init];
	}

	return self;
}

- (BOOL)canGoLeft {
	return currentIndex - 1 >= 0 && availableIdentifiers.count > 0;
}

- (BOOL)canGoRight {
	return availableIdentifiers.count > currentIndex + 1;
}

- (RAHostedAppView *)viewToTheLeft {
	if (self.canGoLeft) {
		return nil;
	}
	NSString *ident = [availableIdentifiers objectAtIndex:currentIndex - 1];

	if (!ident) {
		return nil;
	}
	if ([cachedViews objectForKey:ident]) {
		return [cachedViews objectForKey:ident];
	}

	RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:ident];
	[view preloadApp];
	[cachedViews setObject:view forKey:ident];
	return view;

}

- (RAHostedAppView *)viewToTheRight {
	if (self.canGoRight) {
		return nil;
	}
	NSString *ident = [availableIdentifiers objectAtIndex:currentIndex + 1];

	if (!ident) {
		return nil;
	}
	if ([cachedViews objectForKey:ident]) {
		return [cachedViews objectForKey:ident];
	}

	RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:ident];
	[view preloadApp];
	[cachedViews setObject:view forKey:ident];
	return view;
}

- (RAHostedAppView *)viewAtCurrentIndex {
	NSString *ident = [availableIdentifiers objectAtIndex:currentIndex];

	if (!ident) {
		return nil;
	}
	if ([cachedViews objectForKey:ident]) {
		return [cachedViews objectForKey:ident];
	}

	RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:ident];
	[view preloadApp];
	[cachedViews setObject:view forKey:ident];
	return view;
}

- (void)goToTheLeft {
	if (!self.canGoLeft) {
		return;
	}

	currentIndex--;
}

- (void)goToTheRight {
	if (!self.canGoRight) {
		return;
	}

	currentIndex++;
}

@end
