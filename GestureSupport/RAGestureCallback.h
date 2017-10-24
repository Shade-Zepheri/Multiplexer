typedef NS_ENUM(NSInteger, RAGestureCallbackResult) {
	RAGestureCallbackResultSuccessAndContinue,
	RAGestureCallbackResultFailure,
	RAGestureCallbackResultSuccessAndStop,

	RAGestureCallbackResultSuccess = RAGestureCallbackResultSuccessAndContinue,
};

@protocol RAGestureCallbackProtocol
- (BOOL)RAGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity;
- (RAGestureCallbackResult)RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge;
@end

typedef BOOL(^RAGestureConditionBlock)(CGPoint location, CGPoint velocity);
typedef RAGestureCallbackResult(^RAGestureCallbackBlock)(UIGestureRecognizerState state, CGPoint location, CGPoint velocity);

typedef NSUInteger RAGesturePriority;

extern RAGesturePriority const RAGesturePriorityLow;
extern RAGesturePriority const RAGesturePriorityHigh;
extern RAGesturePriority const RAGesturePriorityDefault;

@interface RAGestureCallback : NSObject

@property (nonatomic, copy) RAGestureCallbackBlock callbackBlock;
@property (nonatomic, copy) RAGestureConditionBlock conditionBlock;
// OR
@property (nonatomic, strong) NSObject<RAGestureCallbackProtocol> *target;

@property (nonatomic) UIRectEdge screenEdge;
@property (nonatomic) RAGesturePriority priority;
@property (nonatomic, copy) NSString *identifier;

@end
