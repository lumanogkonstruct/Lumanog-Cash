#import "HFRealmGate.h"
#import "HFVaultSeal.h"

@implementation HFRealmGate

+ (instancetype)shared {
    static HFRealmGate *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFRealmGate new];
    });
    return ins;
}

- (nullable NSString *)hf_realmCurrent {
    return [HFVaultSeal kKappaBaseURL];
}

- (BOOL)hf_realmReady {
    return [self hf_realmCurrent].length > 0;
}

- (void)hf_realmWipe {
}

- (void)hf_realmPull:(HFRealmOK)ok fail:(HFRealmFail)fail {
    NSString *url = [self hf_realmCurrent];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[HFRealmGate][Cache] final baseURL=%@", url);
        if (url.length) {
            if (ok) ok(url);
        } else if (fail) {
            fail([NSError errorWithDomain:@"HFRealmGate" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"baseURL empty"}]);
        }
    });
}

- (void)hf_realmRepull:(HFRealmOK)ok fail:(HFRealmFail)fail {
    [self hf_realmPull:ok fail:fail];
}

- (void)hf_realmCheck:(NSString *)url done:(void (^)(BOOL))done {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (done) done(url.length > 0);
    });
}

- (void)hf_realmRotate:(HFRealmOK)ok fail:(HFRealmFail)fail {
    [self hf_realmPull:ok fail:fail];
}

- (void)hf_realmBoot:(HFRealmOK)ok fail:(HFRealmFail)fail {
    [self hf_realmPull:ok fail:fail];
}

@end
