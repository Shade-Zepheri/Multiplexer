#import "RAAlertItem.h"

%subclass RAAlertItem : SBAlertItem
%property (copy, nonatomic) NSArray *alertActions;
%property (copy, nonatomic) NSString *title;
%property (copy, nonatomic) NSString *message;

%new
+ (instancetype)alertItemWithTitle:(NSString *)title andMessage:(NSString *)message {
    return [[self alloc] initWithTitle:title andMessage:message];
}

%new
- (instancetype)initWithTitle:(NSString *)title andMessage:(NSString *)message {
    self = [self init];
    if (self) {
        self.title = title;
        self.message = message;
    }

    return self;
}

- (void)configure:(BOOL)animated requirePasscodeForActions:(BOOL)requirePasscode {
    %orig;

    _SBAlertController *alertController = [self alertController];

    NSString *title = self.title;
    alertController.title = title;

    NSString *message = self.message;
    alertController.message = message;

    for (UIAlertAction *alertAction in self.alertActions) {
        [alertController addAction:alertAction];
    }
}

- (BOOL)dismissOnLock {
    return YES;
}

%end
