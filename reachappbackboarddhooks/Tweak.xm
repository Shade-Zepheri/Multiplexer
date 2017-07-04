#import <IOKit/hid/IOHIDEventSystem.h>
#import <IOKit/IOKitLib.h>
#import "RAMessaging.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

static NSInteger const CTRL_KEY = 224;
static NSInteger const CMD_KEY = 231;
static NSInteger const CMD_KEY2 = 227;
static NSInteger const SHIFT_KEY = 229;
static NSInteger const SHIFT_KEY2 = 225;
static NSInteger const ALT_KEY = 226;
static NSInteger const ALT_KEY2 = 230;
static NSInteger const D_KEY = 7;
static NSInteger const BKSPCE_KEY = 42;
static NSInteger const ARROW_RIGHT_KEY = 79;
static NSInteger const ARROW_LEFT_KEY = 80;
static NSInteger const ARROW_UP_KEY = 82;
static NSInteger const ARROW_DOWN_KEY = 81;
static NSInteger const EQUALS_OR_PLUS_KEY = 46;

IOHIDEventSystemCallback eventCallback = NULL;
BOOL isControlKeyDown = NO;
BOOL isWindowsKeyDown = NO;
BOOL isShiftKeyDown = NO;
BOOL isAltKeyDown = NO;

CPDistributedMessagingCenter *center;

// TODO: Ensure all keyboard commands do not conflict with
// https://support.apple.com/en-us/HT201236

void handle_event(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event) {
	if (IOHIDEventGetType(event) == kIOHIDEventTypeKeyboard) {
		IOHIDEventRef event2 = IOHIDEventCreateCopy(kCFAllocatorDefault, event);

		BOOL isDown = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldKeyboardDown);
		int key = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldKeyboardUsage);

		switch (key) {
			case CTRL_KEY:
				isControlKeyDown = isDown;
				break;
			case CMD_KEY:
			case CMD_KEY2:
				isWindowsKeyDown = isDown;
				break;
			case SHIFT_KEY:
			case SHIFT_KEY2:
				isShiftKeyDown = isDown;
				break;
			case ALT_KEY:
			case ALT_KEY2:
				isAltKeyDown = isDown;
				break;
		}

		if (isDown && isWindowsKeyDown && isControlKeyDown) {
			switch (key) {
				case ARROW_LEFT_KEY:
					[center sendMessageName:RAMessagingGoToDesktopOnTheLeftMessageName userInfo:nil];
					break;
				case ARROW_RIGHT_KEY:
					[center sendMessageName:RAMessagingGoToDesktopOnTheRightMessageName userInfo:nil];
					break;
				case BKSPCE_KEY:
					[center sendMessageName:RAMessagingDetachCurrentAppMessageName userInfo:nil];
					break;
				case D_KEY:
				case EQUALS_OR_PLUS_KEY:
					[center sendMessageName:RAMessagingAddNewDesktopMessageName userInfo:nil];
					break;
			}
		} else if (isDown && isWindowsKeyDown && isAltKeyDown) {
			switch (key) {
				case ARROW_LEFT_KEY:
					[center sendMessageName:RAMessagingSnapFrontMostWindowLeftMessageName userInfo:nil];
					break;
				case ARROW_RIGHT_KEY:
					[center sendMessageName:RAMessagingSnapFrontMostWindowRightMessageName userInfo:nil];
					break;
				case ARROW_UP_KEY:
					[center sendMessageName:RAMessagingMaximizeAppMessageName userInfo:nil];
					break;
				case ARROW_DOWN_KEY:
					[center sendMessageName:RAMessagingCloseAppMessageName userInfo:nil];
					break;
			}
		}
	}

	eventCallback(target, refcon, service, event);
}

%hookf(Boolean, "_IOHIDEventSystemOpen", IOHIDEventSystemRef system, IOHIDEventSystemCallback callback, void* target, void* refcon, void* unused) {
	eventCallback = callback;
	return %orig(system, handle_event, target, refcon, unused);
}

@interface BKEventDestination : NSObject
- (instancetype)initWithPid:(NSUInteger)arg1 clientID:(NSString*)arg2;
@end

%hook BKEventFocusManager
- (BKEventDestination*)destinationForFocusedEventWithDisplay:(__unsafe_unretained id)arg1 {
	NSDictionary *response = [center sendMessageAndReceiveReplyName:RAMessagingGetFrontMostAppInfoMessageName userInfo:nil];

	if (response) {
		int pid = [response[@"pid"] unsignedIntValue];
		NSString *clientId = response[@"bundleIdentifier"];

		if (pid && clientId) {
			return [[[%c(BKEventDestination) alloc] initWithPid:pid clientID:clientId] autorelease];
		}
	}
	return %orig;
}
%end

/*
%hook CAWindowServerDisplay
- (unsigned int)contextIdAtPosition:(CGPoint)point
{
    unsigned int cid = %orig;

    if (keyboardWindow)
    {
        if (cid == keyboardWindow.contextId)
        {
            UIGraphicsBeginImageContextWithOptions(keyboardWindow.bounds.size, keyboardWindow.opaque, 0.0);
            [keyboardWindow drawViewHierarchyInRect:keyboardWindow.bounds afterScreenUpdates:NO];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            unsigned char pixel[1] = {0};
            CGContextRef context = CGBitmapContextCreate(pixel,
                                                         1, 1, 8, 1, NULL,
                                                         kCGImageAlphaOnly);
            UIGraphicsPushContext(context);
            [image drawAtPoint:CGPointMake(-point.x, -point.y)];
            UIGraphicsPopContext();
            CGContextRelease(context);
            CGFloat alpha = pixel[0]/255.0f;
            BOOL transparent = alpha < 1.f;
            if (!transparent)
                return cid;
        }
    }
    return cid;
}
%end
*/

%ctor {
	center = [%c(CPDistributedMessagingCenter) centerNamed:@"com.efrederickson.reachapp.messaging.server"];

	void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
	if (handle) {
		void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*) = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
		rocketbootstrap_distributedmessagingcenter_apply(center);
		dlclose(handle);
	}
}
