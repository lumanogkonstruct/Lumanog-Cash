#import "HFQuillVault.h"
#import "HFVaultSeal.h"
#import "HFCipherTag.h"

static NSMutableArray<NSString *> *sHFHistoryMobiles;

@implementation HFQuillVault

+ (void)hf_quillPersist:(NSString *)uid gate:(NSString *)gate {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:uid ?: @"" forKey:[HFVaultSeal kXiUserSlot]];
    [ud setObject:gate ?: @"" forKey:[HFVaultSeal kOmicronGate]];
    [ud synchronize];
}

+ (void)hf_quillPersistPhone:(NSString *)phone {
    [[NSUserDefaults standardUserDefaults] setObject:phone ?: @"" forKey:[HFVaultSeal kPhoneSlot]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)hf_quillUid {
    NSString *s = [[NSUserDefaults standardUserDefaults] stringForKey:[HFVaultSeal kXiUserSlot]];
    return s ?: @"";
}

+ (NSString *)hf_quillGate {
    NSString *s = [[NSUserDefaults standardUserDefaults] stringForKey:[HFVaultSeal kOmicronGate]];
    return s ?: @"";
}

+ (NSString *)hf_quillPhone {
    NSString *s = [[NSUserDefaults standardUserDefaults] stringForKey:[HFVaultSeal kPhoneSlot]];
    return s ?: @"";
}

+ (void)hf_quillErase {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:[HFVaultSeal kXiUserSlot]];
    [ud removeObjectForKey:[HFVaultSeal kOmicronGate]];
    [ud removeObjectForKey:[HFVaultSeal kPhoneSlot]];
    [ud synchronize];
}

+ (NSString *)hf_quillAnchor {
    return [HFCipherTag hf_tagAnchor];
}

+ (nullable NSString *)hf_quillVisageSeal {
    // Uninstall clears UserDefaults but not Keychain. No flag → this install has no seal yet.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:[HFVaultSeal kVisageSealFlag]]) {
        return nil;
    }
    return [HFCipherTag hf_tagVisageSeal];
}

+ (void)hf_quillPutVisageSeal:(NSString *)seal {
    [HFCipherTag hf_tagPutVisageSeal:seal];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[HFVaultSeal kVisageSealFlag]];
}

+ (void)hf_quillWipeVisageSeal {
    [HFCipherTag hf_tagWipeVisageSeal];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[HFVaultSeal kVisageSealFlag]];
}

+ (void)hf_quillNoteMobile:(NSString *)mobile {
    NSString *m = [mobile stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!m.length) return;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sHFHistoryMobiles = [NSMutableArray array];
    });
    [sHFHistoryMobiles addObject:m];
}

+ (NSString *)hf_quillHistoryMobiles {
    if (sHFHistoryMobiles.count == 0) return @"";
    NSMutableArray *uniq = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];
    for (NSString *m in sHFHistoryMobiles) {
        if (![seen containsObject:m]) {
            [seen addObject:m];
            [uniq addObject:m];
        }
    }
    return [uniq componentsJoinedByString:@","];
}

+ (void)hf_quillWipeHistoryMobiles {
    if (sHFHistoryMobiles.count) [sHFHistoryMobiles removeAllObjects];
}

@end
