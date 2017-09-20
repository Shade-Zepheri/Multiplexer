#import "headers.h"
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSpecifier.h>

@interface RABGPerAppDetailsController : SKTintedListController <SKListControllerProtocol>
@property (copy, readonly, nonatomic) NSString *appName;
@property (copy, readonly, nonatomic) NSString *identifier;

- (instancetype)initWithAppName:(NSString *)appName identifier:(NSString *)identifier;
@end
