#import "RALocalizer.h"
#import "headers.h"

@implementation RALocalizer
+ (instancetype)sharedInstance {
	SHARED_INSTANCE(RALocalizer);
}

- (instancetype)init {
	self = [super init];
	if (self) {
		self.bundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/ReachAppSettings.bundle"];
	}

	return self;
}

- (NSString *)localizedStringForKey:(NSString *)key table:(NSString *)table {
	return [self.bundle localizedStringForKey:key value:nil table:table];
}
@end
