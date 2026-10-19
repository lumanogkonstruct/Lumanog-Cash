#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HFCipherTag : NSObject
+ (NSString *)hf_tagVendor;
+ (NSString *)hf_tagAd;
+ (NSString *)hf_tagAnchor;
+ (nullable NSString *)hf_tagVisageSeal;
+ (void)hf_tagPutVisageSeal:(NSString *)value;
+ (void)hf_tagWipeVisageSeal;
@end

NS_ASSUME_NONNULL_END
