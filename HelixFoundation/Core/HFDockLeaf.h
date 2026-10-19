#import "HFCanvasRoot.h"

NS_ASSUME_NONNULL_BEGIN

/// Empty Tab roots (Home / Order / Me shells)
@interface HFDockLeafHome : HFCanvasRoot
@end

@interface HFDockLeafOrder : HFCanvasRoot
/// Focus filter chip by list API orderStatus (20/10/30/40) and reload.
- (void)hf_orderFocusStatus:(NSInteger)orderStatus;
@end

@interface HFDockLeafMe : HFCanvasRoot
@end

NS_ASSUME_NONNULL_END
