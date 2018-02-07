#import "RACompatibilitySystem.h"
#include <sys/sysctl.h>
#include <sys/utsname.h>
#import <UIKit/UIKit.h>
#import "headers.h"
#import "RAWarningAlertItem.h"

@implementation RACompatibilitySystem
+ (NSString *)aggregateSystemInfo {
	NSMutableString *ret = [[NSMutableString alloc] init];

	struct utsname systemInfo;
	uname(&systemInfo);
	NSString *sysInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

	[ret appendString:[NSString stringWithFormat:@"%@, %@ %@\n", sysInfo, [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion]];

	return ret;
}

+ (void)showWarning:(NSString *)info {
	NSString *message = [NSString stringWithFormat:@"System info: %@\n\nWARNING: POTENTIAL INCOMPATIBILITY DETECTED\n%@", [self aggregateSystemInfo], info];

  RAWarningAlertItem *alertItem = [%c(RAWarningAlertItem) alertItemWithTitle:@"Multiplexer Compatibility" andMessage:message];
  [alertItem.class activateAlertItem:alertItem];
}

+ (void)showError:(NSString *)info {
	NSString *message = [NSString stringWithFormat:@"System info: %@\n\n***ERROR***: POTENTIAL INCOMPATIBILITY DETECTED\n%@", [self aggregateSystemInfo], info];

  RAWarningAlertItem *alertItem = [%c(RAWarningAlertItem) alertItemWithTitle:@"Multiplexer Compatibility" andMessage:message];
  [alertItem.class activateAlertItem:alertItem];
}

@end
