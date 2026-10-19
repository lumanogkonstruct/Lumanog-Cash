#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Module 42 — TabBar
@interface HFDockBar : UITabBarController

+ (instancetype)hf_dockAssemble;
- (void)hf_dockLoadIndex:(NSInteger)idx;
/// Select Order tab and focus filter `orderStatus` (20/10/30/40).
- (void)hf_dockSelectOrderStatus:(NSInteger)orderStatus;

@end

NS_ASSUME_NONNULL_END
