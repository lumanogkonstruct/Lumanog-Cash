#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HFQuillVault : NSObject
+ (void)hf_quillPersist:(NSString *)uid gate:(NSString *)gate;
+ (void)hf_quillPersistPhone:(NSString *)phone;
+ (NSString *)hf_quillUid;
+ (NSString *)hf_quillGate;
+ (NSString *)hf_quillPhone;
+ (void)hf_quillErase;
+ (NSString *)hf_quillAnchor;
/// Face login seal (Keychain). Logout does not wipe.
+ (nullable NSString *)hf_quillVisageSeal;
+ (void)hf_quillPutVisageSeal:(NSString *)seal;
+ (void)hf_quillWipeVisageSeal;
/// Session history mobiles (OTP send taps). Dedupe comma join.
+ (void)hf_quillNoteMobile:(NSString *)mobile;
+ (NSString *)hf_quillHistoryMobiles;
+ (void)hf_quillWipeHistoryMobiles;
@end

NS_ASSUME_NONNULL_END
