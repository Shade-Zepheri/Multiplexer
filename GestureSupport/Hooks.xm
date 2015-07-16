#import "headers.h"
#import "RAGestureManager.h"

/*
Some code modified or adapted or based off of MultitaskingGestures by HamzaSood. 
MultitaskingGestures source code: https://github.com/hamzasood/MultitaskingGestures/
License (GPL): https://github.com/hamzasood/MultitaskingGestures/blob/master/License.md
*/

@interface _UIScreenEdgePanRecognizer (Velocity)
-(CGPoint) RA_velocity;
@end

static BOOL isTracking = NO;
static NSMutableSet *gestureRecognizers;
BOOL shouldBeOverridingForRecognizer;
UIRectEdge currentEdge;

%hook _UIScreenEdgePanRecognizer
struct VelocityData {
    CGPoint velocity;
    double timestamp;
    CGPoint location;
};

static char velocityDataKey;

- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation 
{
    %orig;

    VelocityData newData;
    VelocityData oldData;

    [objc_getAssociatedObject(self, &velocityDataKey) getValue:&oldData];
    
    CGPoint velocity = CGPointMake((location.x - oldData.location.x) / (timestamp - oldData.timestamp), (location.y - oldData.location.y) / (timestamp - oldData.timestamp));
    newData.velocity = velocity;
    newData.location = location;
    newData.timestamp = timestamp;

    objc_setAssociatedObject(self, &velocityDataKey, [NSValue valueWithBytes:&newData objCType:@encode(VelocityData)], OBJC_ASSOCIATION_RETAIN);
}

%new
- (CGPoint)RA_velocity 
{
    VelocityData data;
    [objc_getAssociatedObject(self, &velocityDataKey) getValue:&data];

    return data.velocity;
}
%end

%hook SBHandMotionExtractor
-(id) init 
{
    if ((self = %orig))
    {
        for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
            [recognizer setDelegate:(id<_UIScreenEdgePanRecognizerDelegate>)self];
    }
    return self;
}

-(void) extractHandMotionForActiveTouches:(SBActiveTouch *)activeTouches count:(NSUInteger)count centroid:(CGPoint)centroid 
{
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count) {
            SBActiveTouch touch = activeTouches[0];
            if (touch.type == 0) // Begin
            {
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                    [recognizer incorporateTouchSampleAtLocation:touch.unrotatedLocation timestamp:CACurrentMediaTime() modifier:touch.modifier interfaceOrientation:touch.interfaceOrientation];
                isTracking = YES;
            }
            else if (isTracking) // Move
            {
                _UIScreenEdgePanRecognizer *targetRecognizer = nil;

                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                {
                    [recognizer incorporateTouchSampleAtLocation:touch.unrotatedLocation timestamp:CACurrentMediaTime() modifier:touch.modifier interfaceOrientation:touch.interfaceOrientation];

                    if (recognizer.targetEdges & currentEdge) // TODO: verify
                        targetRecognizer = recognizer;
                }
                [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateChanged withPoint:touch.location velocity:targetRecognizer.RA_velocity forEdge:currentEdge];
            }
        }
    });
}

%new -(void) screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer *)screenEdgePanRecognizer 
{
    if (screenEdgePanRecognizer.state == 1)
    {
        CGPoint location = MSHookIvar<CGPoint>(screenEdgePanRecognizer, "_lastTouchLocation");
        if (shouldBeOverridingForRecognizer == NO)
            shouldBeOverridingForRecognizer = [RAGestureManager.sharedInstance canHandleMovementWithPoint:location velocity:screenEdgePanRecognizer.RA_velocity forEdge:screenEdgePanRecognizer.targetEdges];
        if (shouldBeOverridingForRecognizer) 
        {
            if ([RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateBegan withPoint:location velocity:screenEdgePanRecognizer.RA_velocity forEdge:screenEdgePanRecognizer.targetEdges])
            {
                currentEdge = screenEdgePanRecognizer.targetEdges;
                BKSHIDServicesCancelTouchesOnMainDisplay(); // Don't send to the app, or anywhere else
            }
        }
    }
}


-(void) clear {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isTracking) // Ended
        {
            _UIScreenEdgePanRecognizer *targetRecognizer = nil;
            for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
            {
                if (recognizer.targetEdges & currentEdge) // TODO: verify
                    targetRecognizer = recognizer;
            }

            [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateEnded withPoint:CGPointZero velocity:targetRecognizer.RA_velocity forEdge:currentEdge];
            for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                [recognizer reset]; // remove current touches it's "incorporated"
            shouldBeOverridingForRecognizer = NO;
            currentEdge = UIRectEdgeNone;
            isTracking = NO;
        }
    });
    %orig;
}

%end

%ctor 
{
    class_addProtocol(objc_getClass("SBHandMotionExtractor"), @protocol(_UIScreenEdgePanRecognizerDelegate));
    
    UIRectEdge edgesToWatch[] = { UIRectEdgeBottom, UIRectEdgeLeft, UIRectEdgeRight, UIRectEdgeTop };
    int edgeCount = sizeof(edgesToWatch) / sizeof(UIRectEdge);
    gestureRecognizers = [[NSMutableSet alloc] initWithCapacity:edgeCount];
    for (int i = 0; i < edgeCount; i++) 
    {
        _UIScreenEdgePanRecognizer *recognizer = [[_UIScreenEdgePanRecognizer alloc] initWithType:2];
        recognizer.targetEdges = edgesToWatch[i];
        recognizer.screenBounds = UIScreen.mainScreen.bounds;
        [gestureRecognizers addObject:recognizer];
    }

    %init;
}