#import "headers.h"

@interface CALayerHost : CALayer
@property (assign) unsigned int contextId;
@end

@interface RARemoteKeyboardView : UIView {
	BOOL update;
}
@property (copy, nonatomic) NSString *identifier;
@property (strong, nonatomic) CALayerHost *layerHost;
- (void)connectToKeyboardWindowForApp:(NSString *)identifier;
@end
