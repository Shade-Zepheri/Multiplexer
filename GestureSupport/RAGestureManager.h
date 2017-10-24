#import "headers.h"
#import "RAGestureCallback.h"

@interface RAGestureManager : NSObject {
	NSMutableArray *gestures;
	NSMutableDictionary *ignoredAreas;
}
+ (instancetype)sharedInstance;

- (void)addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString *)identifier priority:(RAGesturePriority)priority;
- (void)addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString *)identifier;
- (void)addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol> *)target forEdge:(UIRectEdge)screenEdge identifier:(NSString *)identifier;
- (void)addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol> *)target forEdge:(UIRectEdge)screenEdge identifier:(NSString *)identifier priority:(RAGesturePriority)priority;
- (void)addGesture:(RAGestureCallback *)callback;
- (void)removeGestureWithIdentifier:(NSString *)identifier;

- (BOOL)canHandleMovementWithPoint:(CGPoint)point velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge;
- (BOOL)handleMovementOrStateUpdate:(UIGestureRecognizerState)state withPoint:(CGPoint)point velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge;

- (void)ignoreSwipesBeginningInRect:(CGRect)area forIdentifier:(NSString *)identifier;
- (void)stopIgnoringSwipesForIdentifier:(NSString *)identifier;
- (void)ignoreSwipesBeginningOnSide:(UIRectEdge)side aboveYAxis:(NSUInteger)axis forIdentifier:(NSString *)identifier;
- (void)ignoreSwipesBeginningOnSide:(UIRectEdge)side belowYAxis:(NSUInteger)axis forIdentifier:(NSString *)identifier;
@end
