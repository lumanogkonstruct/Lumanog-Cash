#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Module 43 stub — floating button shell
@interface HFFloatOrb : NSObject
+ (instancetype)shared;
- (void)hf_orbShow;
- (void)hf_orbHide;
- (void)hf_orbSetURL:(nullable NSString *)url;
@end

NS_ASSUME_NONNULL_END
