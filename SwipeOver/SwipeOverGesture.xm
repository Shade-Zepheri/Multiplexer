#import "RAGestureManager.h"
#import "RASwipeOverManager.h"
#import "RAKeyboardStateListener.h"
#import "RAMissionControlManager.h"
#import "PDFImage.h"
#import "PDFImageOptions.h"

UIImageView *grabberView;
BOOL isShowingGrabber = NO;
BOOL isPastGrabber = NO;
NSDate *lastTouch;
CGPoint startingPoint;

CGRect adjustFrameForRotation()
{
    CGFloat portraitWidth = 30;
    CGFloat portraitHeight = 50;
    switch ([[UIApplication.sharedApplication _accessibilityFrontMostApplication] statusBarOrientation])
    {
        case UIInterfaceOrientationPortrait:
            NSLog(@"[ReachApp] portrait");
            return (CGRect){ { UIScreen.mainScreen.bounds.size.width - portraitWidth + 5, (UIScreen.mainScreen.bounds.size.height - portraitHeight) / 2 }, { portraitWidth, portraitHeight } };
        case UIInterfaceOrientationPortraitUpsideDown:
            NSLog(@"[ReachApp] portrait upside down");
            return (CGRect){ { 0, 0}, { 50, 50 } };
        case UIInterfaceOrientationLandscapeLeft:
            NSLog(@"[ReachApp] landscape left");
            return (CGRect){ { (UIScreen.mainScreen.bounds.size.width - portraitHeight) / 2, 0 - 5 }, { portraitHeight, portraitWidth } };
        case UIInterfaceOrientationLandscapeRight:
            NSLog(@"[ReachApp] landscape right");
            return (CGRect){ { UIScreen.mainScreen.bounds.size.height - portraitHeight, UIScreen.mainScreen.bounds.size.width - portraitWidth }, { portraitHeight, portraitWidth } };
    }
    return CGRectZero;
}

CGAffineTransform adjustTransformRotation()
{    
    switch ([[UIApplication.sharedApplication _accessibilityFrontMostApplication] statusBarOrientation])
    {
        case UIInterfaceOrientationPortrait:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    }
    return CGAffineTransformIdentity;
}

%ctor
{
    [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
        lastTouch = [NSDate date];

        if ([[%c(SBUIController) sharedInstance] shouldShowControlCenterTabControlOnFirstSwipe])
        {
            if (isShowingGrabber == NO && isPastGrabber == NO)
            {
                isShowingGrabber = YES;

                //grabberView = [[%c(SBControlCenterGrabberView) alloc] initWithFrame:adjustFrameForRotation()];
                //[grabberView.chevronView setState:1 animated:NO];
                //grabberView.chevronView.transform = adjustTransformRotation();
                grabberView = [[UIImageView alloc] initWithFrame:adjustFrameForRotation()];
                grabberView.image = [[PDFImage imageWithContentsOfFile:@"/Library/ReachApp/Grabber.pdf"] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(grabberView.frame.size.width, grabberView.frame.size.height)]];

                grabberView.backgroundColor = [UIColor clearColor];
                grabberView.layer.cornerRadius = 5;
                [UIWindow.keyWindow addSubview:grabberView]; // The desktop view most likely

                static void (^dismisser)() = ^{ // top kek, needs "static" so it's not a local, self-retaining block
                    if ([[NSDate date] timeIntervalSinceDate:lastTouch] > 2)
                    {
                        [UIView animateWithDuration:0.2 animations:^{
                            grabberView.frame = CGRectOffset(grabberView.frame, 40, 0);
                        } completion:^(BOOL _) {
                            [grabberView removeFromSuperview];
                            grabberView = nil;
                            isShowingGrabber = NO;
                            isPastGrabber = NO;
                        }];
                    }
                    else if (grabberView) // left there
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            dismisser();
                        });
                    }
                };
                dismisser();

                return RAGestureCallbackResultSuccess;
            }
            else if (CGRectContainsPoint(grabberView.frame, location))
            {
                [grabberView removeFromSuperview];
                grabberView = nil;
                isShowingGrabber = NO;
                isPastGrabber = YES;
            }
            else if (isPastGrabber == NO)
            {
                startingPoint = CGPointZero;
                isPastGrabber = NO;
                return RAGestureCallbackResultSuccess;
            }
        }

        CGPoint translation;
        switch (state) {
            case UIGestureRecognizerStateBegan:
                startingPoint = location;
                break;
            case UIGestureRecognizerStateChanged:
                translation = CGPointMake(location.x - startingPoint.x, location.y - startingPoint.y);
                break;
            case UIGestureRecognizerStateEnded:
                startingPoint = CGPointZero;
                isPastGrabber = NO;
                break;
        }

        if (![RASwipeOverManager.sharedInstance isUsingSwipeOver])
            [RASwipeOverManager.sharedInstance startUsingSwipeOver];
        
        if (state == UIGestureRecognizerStateChanged)
            [RASwipeOverManager.sharedInstance sizeViewForTranslation:translation state:state];

        return RAGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
        if (RAKeyboardStateListener.sharedInstance.visible)
        {
            CGRect realKBFrame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, RAKeyboardStateListener.sharedInstance.size.width, RAKeyboardStateListener.sharedInstance.size.height);
            realKBFrame = CGRectOffset(realKBFrame, 0, -realKBFrame.size.height);

            if (CGRectContainsPoint(realKBFrame, location))
                return NO;
        }
        
        return ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && !RAMissionControlManager.sharedInstance.isShowingMissionControl;
    } forEdge:UIRectEdgeRight identifier:@"com.efrederickson.reachapp.swipeover.systemgesture" priority:RAGesturePriorityDefault];
}