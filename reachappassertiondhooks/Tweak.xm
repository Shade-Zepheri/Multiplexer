#import <Foundation/Foundation.h>
#import <version.h>

%group iOS8
%hookf(int, "_BSAuditTokenTaskHasEntitlement", id connection, NSString *entitlement) {
  if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
    return true;
  }

  return %orig;
}
%end

%group iOS9
%hookf(int, "_BSXPCConnectionHasEntitlement", id connection, NSString *entitlement) {
  if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
    return true;
  }

  return %orig;
}
%end

%ctor {
  // We can never be too sure (im pretty sure we can)
  if (IS_IOS_OR_NEWER(iOS_9_0)) {
    %init(iOS9);
  } else {
    %init(iOS8);
  }
}
