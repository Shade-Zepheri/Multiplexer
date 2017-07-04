#import "headers.h"
#import "RAGestureManager.h"

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#include <IOKit/hid/IOHIDEventSystem.h>
#include <IOKit/hid/IOHIDEventSystemClient.h>
#include <stdio.h>
#include <dlfcn.h>

typedef struct __IOHIDServiceClient * IOHIDServiceClientRef;
typedef void* (*clientCreatePointer)(const CFAllocatorRef);
extern "C" void BKSHIDServicesCancelTouchesOnMainDisplay();

@interface _UIScreenEdgePanRecognizer (Velocity)
- (CGPoint)RA_velocity;
@end

static BOOL isTracking = NO;
static NSMutableSet *gestureRecognizers;
UIRectEdge currentEdge9;

typedef struct {
    CGPoint velocity;
    double timestamp;
    CGPoint location;
} VelocityData;

%hook _UIScreenEdgePanRecognizer
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation forceState:(int)arg5 {
  %orig;

  VelocityData newData;
  VelocityData oldData;

  [objc_getAssociatedObject(self, @selector(RA_velocityData)) getValue:&oldData];

  // this is really quite simple, it calculates a velocity based off of
  // (current location - last location) / (time taken to move from last location to current location)
  // which effectively gives you a CGPoint of where it would end if the user continued the gesture.
  CGPoint velocity = CGPointMake((location.x - oldData.location.x) / (timestamp - oldData.timestamp), (location.y - oldData.location.y) / (timestamp - oldData.timestamp));
  newData.velocity = velocity;
  newData.location = location;
  newData.timestamp = timestamp;

  objc_setAssociatedObject(self, @selector(RA_velocityData), [NSValue valueWithBytes:&newData objCType:@encode(VelocityData)], OBJC_ASSOCIATION_RETAIN);
}

%new
- (CGPoint)RA_velocity {
  VelocityData data;
  [objc_getAssociatedObject(self, @selector(RA_velocityData)) getValue:&data];

  return data.velocity;
}
%end

@interface Hooks9$SBHandMotionExtractorReplacementByMultiplexer : NSObject

@end

@implementation Hooks9$SBHandMotionExtractorReplacementByMultiplexer
- (instancetype)init {
  self = [super init];
  if (self) {
    for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers) {
      [recognizer setDelegate:(id<_UIScreenEdgePanRecognizerDelegate>)self];
    }
  }

  return self;
}

- (void)screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer*)screenEdgePanRecognizer {
  if (screenEdgePanRecognizer.state != UIGestureRecognizerStateBegan) {
    return;
  }

  CGPoint location = screenEdgePanRecognizer._lastTouchLocation;

  if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft && (location.x != 0 && location.y != 0)) {
    location.x = [UIScreen mainScreen].bounds.size.width - location.x;
  } else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown && (location.x != 0 && location.y != 0)) {
      location.x = [UIScreen mainScreen].bounds.size.width - location.x;
  } else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
    CGFloat t = location.y;
    location.y = location.x;
    location.x = t;
  }
  LogDebug(@"[ReachApp] _UIScreenEdgePanRecognizer location: %@", NSStringFromCGPoint(location));
  if ([[RAGestureManager sharedInstance] handleMovementOrStateUpdate:UIGestureRecognizerStateBegan withPoint:location velocity:screenEdgePanRecognizer.RA_velocity forEdge:screenEdgePanRecognizer.targetEdges]) {
    currentEdge9 = screenEdgePanRecognizer.targetEdges;
    BKSHIDServicesCancelTouchesOnMainDisplay(); // This is needed or open apps, etc will still get touch events. For example open settings app + swipeover without this line and you can still scroll up/down through the settings
  }
}
@end

void touch_event(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
  if (IOHIDEventGetType(event) != kIOHIDEventTypeDigitizer) {
    return;
  }

  NSArray *children = (__bridge_transfer NSArray *)IOHIDEventGetChildren(event);
  if ([children count] != 1) {
    return;
  }

  float density = IOHIDEventGetFloatValue((__bridge_transfer __IOHIDEvent *)children[0], (IOHIDEventField)kIOHIDEventFieldDigitizerDensity);

  float x = IOHIDEventGetFloatValue((__bridge_transfer __IOHIDEvent *)children[0], (IOHIDEventField)kIOHIDEventFieldDigitizerX) * CGRectGetWidth([UIScreen mainScreen]._referenceBounds);
  float y = IOHIDEventGetFloatValue((__bridge_transfer __IOHIDEvent *)children[0], (IOHIDEventField)kIOHIDEventFieldDigitizerY) * CGRectGetHeight([UIScreen mainScreen]._referenceBounds);
  CGPoint location = CGPointMake(x, y);

  UIInterfaceOrientation interfaceOrientation = GET_STATUSBAR_ORIENTATION;

  float rotatedX, rotatedY;

  switch (interfaceOrientation) {
    case UIInterfaceOrientationUnknown:
    case UIInterfaceOrientationPortrait:
      rotatedX = x;
      rotatedY = y;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      rotatedX = [UIScreen mainScreen].bounds.size.width - x;
      rotatedY = [UIScreen mainScreen].bounds.size.height - y;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      rotatedX = [UIScreen mainScreen].bounds.size.width - y;
      rotatedY = x;
      break;
    case UIInterfaceOrientationLandscapeRight:
      rotatedX = y;
      rotatedY = [UIScreen mainScreen].bounds.size.height - x;
      break;
  }

  CGPoint rotatedLocation = CGPointMake(rotatedX, rotatedY);

  LogInfo(@"[ReachApp] (%f, %d) %@ -> %@", density, isTracking, NSStringFromCGPoint(location), NSStringFromCGPoint(rotatedLocation));

  if (!isTracking) {
    for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers) {
      [recognizer incorporateTouchSampleAtLocation:location timestamp:CACurrentMediaTime() modifier:1 interfaceOrientation:interfaceOrientation forceState:0];
    }
    isTracking = YES;
  } else if (density == 0 && isTracking) {
    _UIScreenEdgePanRecognizer *targetRecognizer = nil;
    for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers) {
      if (recognizer.targetEdges & currentEdge9) {
        targetRecognizer = recognizer;
      }
    }

    [[RAGestureManager sharedInstance] handleMovementOrStateUpdate:UIGestureRecognizerStateEnded withPoint:CGPointZero velocity:targetRecognizer.RA_velocity forEdge:currentEdge9];
    for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers) {
      [recognizer reset]; // remove current touches it's "incorporated"
    }
    currentEdge9 = UIRectEdgeNone;
    isTracking = NO;

    LogInfo(@"[ReachApp] touch ended.");
  } else {
    _UIScreenEdgePanRecognizer *targetRecognizer = nil;

    for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers) {
      [recognizer incorporateTouchSampleAtLocation:location timestamp:CACurrentMediaTime() modifier:1 interfaceOrientation:interfaceOrientation forceState:0];

      if (recognizer.targetEdges & currentEdge9) {
        targetRecognizer = recognizer;
      }
    }
    [[RAGestureManager sharedInstance] handleMovementOrStateUpdate:UIGestureRecognizerStateChanged withPoint:rotatedLocation velocity:targetRecognizer.RA_velocity forEdge:currentEdge9];
  }
}

static inline void initializeGestures(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  clientCreatePointer clientCreate;
  void *handle = dlopen(0, 9);
  *(void**)(&clientCreate) = dlsym(handle,"IOHIDEventSystemClientCreate");
  IOHIDEventSystemClientRef ioHIDEventSystem = (__IOHIDEventSystemClient *)clientCreate(kCFAllocatorDefault);
  IOHIDEventSystemClientScheduleWithRunLoop(ioHIDEventSystem, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  IOHIDEventSystemClientRegisterEventCallback(ioHIDEventSystem, (IOHIDEventSystemClientEventCallback)touch_event, NULL, NULL);
}

__strong id __static$Hooks9$SBHandMotionExtractorReplacementByMultiplexer;

%ctor {
  if (!IS_IOS_OR_NEWER(iOS_9_0) || !IS_SPRINGBOARD) {
    return;
  }

  @autoreleasepool {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &initializeGestures, CFSTR("SBSpringBoardDidLaunchNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    class_addProtocol(%c(Hooks9$SBHandMotionExtractorReplacementByMultiplexer), @protocol(_UIScreenEdgePanRecognizerDelegate));

    UIRectEdge edgesToWatch[] = { UIRectEdgeBottom, UIRectEdgeLeft, UIRectEdgeRight, UIRectEdgeTop };
    int edgeCount = sizeof(edgesToWatch) / sizeof(UIRectEdge);
    gestureRecognizers = [NSMutableSet setWithCapacity:edgeCount];
    for (int i = 0; i < edgeCount; i++) {
      _UIScreenEdgePanRecognizer *recognizer = [[_UIScreenEdgePanRecognizer alloc] initWithType:2];
      recognizer.targetEdges = edgesToWatch[i];
      recognizer.screenBounds = [UIScreen mainScreen].bounds;
      [gestureRecognizers addObject:recognizer];
    }

    %init;

    __static$Hooks9$SBHandMotionExtractorReplacementByMultiplexer = [[Hooks9$SBHandMotionExtractorReplacementByMultiplexer alloc] init];
  }
}
