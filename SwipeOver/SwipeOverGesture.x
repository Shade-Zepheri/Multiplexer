#import "RAGestureManager.h"
#import "RASwipeOverManager.h"
#import "RAKeyboardStateListener.h"
#import "RAMissionControlManager.h"
#import "PDFImage.h"
#import "PDFImageOptions.h"
#import "RASettings.h"
#import "RAHostManager.h"
#import "RAResourceImageProvider.h"
#import "Multiplexer.h"

UIView *grabberView;
BOOL isShowingGrabber = NO;
BOOL isPastGrabber = NO;
CFTimeInterval startTime;
CGPoint startingPoint;
BOOL firstSwipe = NO;

CGRect adjustFrameForRotation() {
  CGFloat portraitWidth = 30;
  CGFloat portraitHeight = 50;

  CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds);
  CGFloat height = CGRectGetHeight([UIScreen mainScreen].bounds);

  UIInterfaceOrientation orientation = GET_STATUSBAR_ORIENTATION;
  switch (orientation) {
    case UIInterfaceOrientationUnknown:
    case UIInterfaceOrientationPortrait: {
      LogDebug(@"[ReachApp] portrait");
      return CGRectMake(width - portraitWidth + 5, (height - portraitHeight) / 2, portraitWidth, portraitHeight);
    }
    case UIInterfaceOrientationPortraitUpsideDown: {
      LogDebug(@"[ReachApp] portrait upside down");
      return CGRectMake(0, 0, 50, 50);
    }
    case UIInterfaceOrientationLandscapeLeft: {
      LogDebug(@"[ReachApp] landscape left");
      return CGRectMake((width - portraitWidth) / 2, -(portraitWidth / 2), portraitWidth, portraitHeight);
    }
    case UIInterfaceOrientationLandscapeRight: {
      LogDebug(@"[ReachApp] landscape right");
      return CGRectMake((height - portraitHeight / 2), width - portraitWidth - 5, portraitWidth, portraitHeight);
    }
  }
  return CGRectZero;
}

CGPoint adjustCenterForOffscreenSlide(CGPoint center) {
  CGFloat portraitWidth = 30;
  //CGFloat portraitHeight = 50;

  UIInterfaceOrientation orientation = GET_STATUSBAR_ORIENTATION;
  switch (orientation) {
    case UIInterfaceOrientationUnknown:
    case UIInterfaceOrientationPortrait:
      return CGPointMake(center.x + portraitWidth, center.y);
    case UIInterfaceOrientationPortraitUpsideDown:
      return CGPointMake(center.x - portraitWidth, center.y);
    case UIInterfaceOrientationLandscapeLeft:
      return CGPointMake(center.x, center.y - portraitWidth);
    case UIInterfaceOrientationLandscapeRight:
      return CGPointMake(center.x, center.y + portraitWidth);
  }
  return CGPointZero;
}

CGAffineTransform adjustTransformRotation() {
  UIInterfaceOrientation orientation = GET_STATUSBAR_ORIENTATION;
  switch (orientation) {
    case UIInterfaceOrientationUnknown:
    case UIInterfaceOrientationPortrait:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
    case UIInterfaceOrientationPortraitUpsideDown:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    case UIInterfaceOrientationLandscapeLeft:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
    case UIInterfaceOrientationLandscapeRight:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
  }
  return CGAffineTransformIdentity;
}

BOOL swipeOverLocationIsInValidArea(CGFloat y) {
  if (y == 0) {
    return YES; // more than likely, UIGestureRecognizerStateEnded
  }

  switch ([[RASettings sharedInstance] swipeOverGrabArea]) {
    case RAGrabAreaSideAnywhere:
      return YES;
    case RAGrabAreaSideTopThird:
      return y <= CGRectGetHeight([UIScreen mainScreen].bounds) / 3.0;
    case RAGrabAreaSideMiddleThird:
      return y >= CGRectGetHeight([UIScreen mainScreen].bounds) / 3.0 && y <= (CGRectGetHeight([UIScreen mainScreen].bounds) / 3.0) * 2;
    case RAGrabAreaSideBottomThird:
      return y >= (CGRectGetHeight([UIScreen mainScreen].bounds) / 3.0) * 2;
    default:
      return NO;
  }
}

%ctor {
  [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
    startTime = CACurrentMediaTime();

    if ([Multiplexer shouldShowControlCenterGrabberOnFirstSwipe] || [[RASettings sharedInstance] alwaysShowSOGrabber]) {
      if (!isShowingGrabber && !isPastGrabber) {
        firstSwipe = YES;
        isShowingGrabber = YES;

        grabberView = [[UIView alloc] initWithFrame:adjustFrameForRotation()];

        _UIBackdropViewSettings *blurSettings = [_UIBackdropViewSettings settingsForStyle:1 graphicsQuality:10];
        _UIBackdropView *bgView = [[%c(_UIBackdropView) alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(grabberView.frame), CGRectGetHeight(grabberView.frame)) autosizesToFitSuperview:YES settings:blurSettings];
        [grabberView addSubview:bgView];

        //grabberView.backgroundColor = UIColor.redColor;

        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(grabberView.frame) - 20, CGRectGetHeight(grabberView.frame) - 20)];
        imgView.image = [RAResourceImageProvider imageForFilename:@"Grabber" constrainedToSize:CGSizeMake(CGRectGetWidth(grabberView.frame) - 20, CGRectGetHeight(grabberView.frame) - 20)];
        [grabberView addSubview:imgView];
        grabberView.layer.cornerRadius = 5;
        grabberView.clipsToBounds = YES;

        grabberView.transform = adjustTransformRotation();
        //[UIWindow.keyWindow addSubview:grabberView]; // The desktop view most likely
        if ([UIApplication sharedApplication]._accessibilityFrontMostApplication) {
          UIView *appView = [[RAHostManager systemHostViewForApplication:[UIApplication sharedApplication]._accessibilityFrontMostApplication] superview];
          [appView addSubview:grabberView];
        } else {
          UIView *contentView = [[%c(SBUIController) sharedInstance] contentView];
          [contentView addSubview:grabberView];
        }

        static void (^dismisser)() = ^{ // top kek, needs "static" so it's not a local, self-retaining block
          if ((CACurrentMediaTime() - startTime) > 2) {
            [UIView animateWithDuration:0.2 animations:^{
              //grabberView.frame = CGRectOffset(grabberView.frame, 40, 0);
              grabberView.center = adjustCenterForOffscreenSlide(grabberView.center);
            } completion:^(BOOL finished) {
              if (finished) {
                [grabberView removeFromSuperview];
                grabberView = nil;
                isShowingGrabber = NO;
                isPastGrabber = NO;
              }
            }];
          } else if (grabberView) { // left there
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
              dismisser();
            });
          }
        };
        dismisser();

        return RAGestureCallbackResultSuccess;
      } else if (CGRectContainsPoint(grabberView.frame, location) || (isShowingGrabber && !firstSwipe && [[RASettings sharedInstance] swipeOverGrabArea] != RAGrabAreaSideAnywhere && [[RASettings sharedInstance] swipeOverGrabArea] != RAGrabAreaSideMiddleThird)) {
        [grabberView removeFromSuperview];
        grabberView = nil;
        isShowingGrabber = NO;
        isPastGrabber = YES;
      } else if (!isPastGrabber) {
        if (state == UIGestureRecognizerStateEnded) {
          firstSwipe = NO;
        }
        startingPoint = CGPointZero;
        isPastGrabber = NO;
        return RAGestureCallbackResultSuccess;
      }
    }

    CGPoint translation = CGPointZero;
    switch (state) {
      case UIGestureRecognizerStatePossible:
        break;
      case UIGestureRecognizerStateBegan: {
        startingPoint = location;
        break;
      }
      case UIGestureRecognizerStateChanged: {
        translation = CGPointMake(location.x - startingPoint.x, location.y - startingPoint.y);
        break;
      }
      case UIGestureRecognizerStateEnded:
      case UIGestureRecognizerStateCancelled:
      case UIGestureRecognizerStateFailed: {
        startingPoint = CGPointZero;
        isPastGrabber = NO;
        break;
      }
    }

    if (![RASwipeOverManager sharedInstance].usingSwipeOver) {
      [[RASwipeOverManager sharedInstance] startUsingSwipeOver];
    }

    //if (state == UIGestureRecognizerStateChanged)
    [[RASwipeOverManager sharedInstance] sizeViewForTranslation:translation state:state];

    return RAGestureCallbackResultSuccess;
  } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
    if ([RAKeyboardStateListener sharedInstance].visible && ![RASwipeOverManager sharedInstance].usingSwipeOver) {
      CGRect realKBFrame = CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds), [RAKeyboardStateListener sharedInstance].size.width, [RAKeyboardStateListener sharedInstance].size.height);
      realKBFrame = CGRectOffset(realKBFrame, 0, -CGRectGetHeight(realKBFrame));

      if (CGRectContainsPoint(realKBFrame, location) || CGRectGetHeight(realKBFrame) > 50) {
        return NO;
      }
    }

    return [[RASettings sharedInstance] swipeOverEnabled] && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && ![[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && ![[%c(SBNotificationCenterController) sharedInstance] isVisible] && ![[%c(RAMissionControlManager) sharedInstance] isShowingMissionControl] && (swipeOverLocationIsInValidArea(location.y) || isShowingGrabber);
  } forEdge:UIRectEdgeRight identifier:@"com.efrederickson.reachapp.swipeover.systemgesture" priority:RAGesturePriorityDefault];
}