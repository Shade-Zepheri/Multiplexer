#import "RADefaultWidgetSection.h"
#import "RAWidget.h"
#import "RAWidgetSectionManager.h"
#import "headers.h"

@implementation RADefaultWidgetSection
+ (instancetype)sharedDefaultWidgetSection {
	SHARED_INSTANCE2(RADefaultWidgetSection,
		[[RAWidgetSectionManager sharedInstance] registerSection:sharedInstance];
	);
}

- (NSString *)displayName {
	return LOCALIZE(@"WIDGETS", @"Localizable");
}

- (NSString *)identifier {
	return @"com.efrederickson.reachapp.widgets.sections.default";
}
@end

%ctor {
	static id _widget = [RADefaultWidgetSection sharedDefaultWidgetSection];
	[[RAWidgetSectionManager sharedInstance] registerSection:_widget];
}
