#import <version.h>

%hookf(int, "_BSAuditTokenTaskHasEntitlement", id connection, NSString *entitlement) {
  if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
    return true;
  }

  return %orig;
}

// Not sure if this one is still needed though
%hookf(int, "_BSXPCConnectionHasEntitlement", id connection, NSString *entitlement) {
  if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
    return true;
  }

  return %orig;
}
