#import "RAAppIconStatusBarIconView.h"
#import <AppList/ALApplicationList.h>
#import <libstatusbar/UIStatusBarCustomItem.h>
#import <UIKit/_UILegibilityImageSet.h>

%subclass RAAppIconStatusBarIconView : UIStatusBarCustomItemView

- (_UILegibilityImageSet *)contentsImage {
	NSString *identifier = [[self item].indicatorName substringFromIndex:(@"multiplexer-").length];
	UIImage *image = [[ALApplicationList sharedApplicationList] iconOfSize:15 forDisplayIdentifier:identifier];

	return [_UILegibilityImageSet imageFromImage:image withShadowImage:image];
}

- (CGFloat)standardPadding {
	return 4;
}

%end

%ctor {
	dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_LAZY);

	if (%c(UIStatusBarCustomItemView)) {
		%init;
	}
}
