#import "headers.h"

@interface RAWarningAlertItem : SBAlertItem
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *message;

+ (instancetype)alertItemWithTitle:(NSString *)title andMessage:(NSString *)message;
- (instancetype)initWithTitle:(NSString *)title andMessage:(NSString *)message;

@end
