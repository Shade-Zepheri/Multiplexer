#import "headers.h"

@interface RAAlertItem : SBAlertItem
@property (copy, nonatomic) NSArray<UIAlertAction *> *alertActions;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *message;

+ (instancetype)alertItemWithTitle:(NSString *)title andMessage:(NSString *)message;
- (instancetype)initWithTitle:(NSString *)title andMessage:(NSString *)message;

@end
