#import "HFCipherTag.h"
#import "HFVaultSeal.h"
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

@implementation HFCipherTag

+ (NSString *)hf_nullLit { return @"null"; }

+ (nullable NSString *)hf_kcRead:(NSString *)acct {
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [HFVaultSeal kPhiCipherSvc],
        (__bridge id)kSecAttrAccount: acct,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    CFTypeRef out = NULL;
    OSStatus st = SecItemCopyMatching((__bridge CFDictionaryRef)q, &out);
    if (st != errSecSuccess || !out) {
        return nil;
    }
    NSData *data = (__bridge_transfer NSData *)out;
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (s.length == 0 || [s isEqualToString:[self hf_nullLit]]) {
        return nil;
    }
    return s;
}

+ (void)hf_kcWrite:(NSString *)acct value:(NSString *)value {
    if (value.length == 0 || [value isEqualToString:[self hf_nullLit]]) {
        return;
    }
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *del = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [HFVaultSeal kPhiCipherSvc],
        (__bridge id)kSecAttrAccount: acct
    };
    SecItemDelete((__bridge CFDictionaryRef)del);
    NSDictionary *add = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [HFVaultSeal kPhiCipherSvc],
        (__bridge id)kSecAttrAccount: acct,
        (__bridge id)kSecValueData: data,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    };
    SecItemAdd((__bridge CFDictionaryRef)add, NULL);
}

+ (NSString *)hf_md5Upper:(NSString *)src {
    const char *c = src.UTF8String;
    unsigned char dig[CC_MD5_DIGEST_LENGTH];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(c, (CC_LONG)strlen(c), dig);
#pragma clang diagnostic pop
    NSMutableString *out = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [out appendFormat:@"%02X", dig[i]];
    }
    return out;
}

+ (NSString *)hf_tagVendor {
    NSString *cached = [self hf_kcRead:[HFVaultSeal kChiCipherAcctDF]];
    if (cached.length) {
        return cached;
    }
    NSUUID *u = [UIDevice currentDevice].identifierForVendor;
    if (!u) {
        return [self hf_nullLit];
    }
    NSString *s = u.UUIDString;
    [self hf_kcWrite:[HFVaultSeal kChiCipherAcctDF] value:s];
    return s;
}

+ (NSString *)hf_tagAd {
    if (@available(iOS 14, *)) {
        if (ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusAuthorized) {
            return [self hf_nullLit];
        }
    }
    NSString *ad = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
    if (ad.length == 0 || [ad hasPrefix:@"00000000"]) {
        return [self hf_nullLit];
    }
    return ad;
}

+ (nullable NSString *)hf_tagVisageSeal {
    return [self hf_kcRead:[HFVaultSeal kVisageSealAcct]];
}

+ (void)hf_tagPutVisageSeal:(NSString *)value {
    if (value.length == 0) return;
    [self hf_kcWrite:[HFVaultSeal kVisageSealAcct] value:value];
}

+ (void)hf_tagWipeVisageSeal {
    NSDictionary *del = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [HFVaultSeal kPhiCipherSvc],
        (__bridge id)kSecAttrAccount: [HFVaultSeal kVisageSealAcct]
    };
    SecItemDelete((__bridge CFDictionaryRef)del);
}

+ (NSString *)hf_tagAnchor {
    NSString *cached = [self hf_kcRead:[HFVaultSeal kPsiCipherAcctID]];
    if (cached.length) {
        return cached;
    }
    NSString *raw = [NSString stringWithFormat:@"%@-%lld", [NSUUID UUID].UUIDString, (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
    NSString *md = [self hf_md5Upper:raw];
    if (md.length == 0) {
        return [self hf_nullLit];
    }
    [self hf_kcWrite:[HFVaultSeal kPsiCipherAcctID] value:md];
    return md;
}

@end
