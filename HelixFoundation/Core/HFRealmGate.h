#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HFRealmOK)(NSString *baseURL);
typedef void (^HFRealmFail)(NSError * _Nullable error);

@interface HFRealmGate : NSObject

+ (instancetype)shared;

- (nullable NSString *)hf_realmCurrent;
- (BOOL)hf_realmReady;
- (void)hf_realmWipe;
- (void)hf_realmPull:(HFRealmOK)ok fail:(HFRealmFail)fail;
- (void)hf_realmRepull:(HFRealmOK)ok fail:(HFRealmFail)fail;
- (void)hf_realmCheck:(NSString *)url done:(void (^)(BOOL ok))done;
- (void)hf_realmBoot:(HFRealmOK)ok fail:(HFRealmFail)fail;
- (void)hf_realmRotate:(HFRealmOK)ok fail:(HFRealmFail)fail;

@end

NS_ASSUME_NONNULL_END
