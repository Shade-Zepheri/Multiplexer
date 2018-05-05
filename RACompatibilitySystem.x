#import "RACompatibilitySystem.h"
#include <sys/sysctl.h>
#include <sys/utsname.h>
#import <UIKit/UIKit.h>
#import "headers.h"
#import "RAAlertItem.h"

@implementation RACompatibilitySystem
+ (NSString *)aggregateSystemInfo {
    NSMutableString *ret = [NSMutableString string];

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *sysInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    [ret appendString:[NSString stringWithFormat:@"%@, %@ %@\n", sysInfo, [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion]];

    return ret;
}

+ (void)showWarning:(NSString *)info {
    NSString *message = [NSString stringWithFormat:@"System info: %@\n\nWARNING: POTENTIAL INCOMPATIBILITY DETECTED\n%@", [self aggregateSystemInfo], info];

    RAAlertItem *alertItem = [%c(RAAlertItem) alertItemWithTitle:@"Multiplexer Compatibility" andMessage:message];

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alertItem deactivateForButton];
    }];
    alertItem.alertActions = @[action];

    [alertItem.class activateAlertItem:alertItem];
}

+ (void)showError:(NSString *)info {
    NSString *message = [NSString stringWithFormat:@"System info: %@\n\n***ERROR***: POTENTIAL INCOMPATIBILITY DETECTED\n%@", [self aggregateSystemInfo], info];

    RAAlertItem *alertItem = [%c(RAAlertItem) alertItemWithTitle:@"Multiplexer Compatibility" andMessage:message];

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alertItem deactivateForButton];
    }];
    alertItem.alertActions = @[action];

    [alertItem.class activateAlertItem:alertItem];
}

@end
