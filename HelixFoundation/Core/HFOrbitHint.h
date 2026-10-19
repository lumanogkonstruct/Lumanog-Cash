#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Module 01 — Toast / Loading / Popover
@interface HFOrbitHint : NSObject

+ (instancetype)shared;

- (void)hf_orbitPulse:(nullable NSString *)text;
- (void)hf_orbitPulse:(nullable NSString *)text duration:(NSTimeInterval)seconds;

/// Loading：仅遮罩 + 图标；`text` 忽略（统一不展示文字）
- (void)hf_orbitSpin:(nullable NSString *)text;
- (void)hf_orbitHaltSpin;
/// 强制关掉 Loading（忽略嵌套计数）
- (void)hf_orbitForceHaltSpin;

- (void)hf_orbitBubble:(nullable NSString *)text
                anchor:(UIView *)sourceView
                  host:(UIViewController *)presenter;
- (void)hf_orbitBubble:(nullable NSString *)text
                anchor:(UIView *)sourceView
                  host:(UIViewController *)presenter
              duration:(NSTimeInterval)seconds;

@end

NS_ASSUME_NONNULL_END
