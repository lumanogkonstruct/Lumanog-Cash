#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HFParcelConfig;

@interface HFLedgerFetch : NSObject
+ (instancetype)shared;
- (void)hf_ledgerForce:(void (^)(HFParcelConfig * _Nullable cfg))done;
- (void)hf_ledgerObtain:(void (^)(HFParcelConfig * _Nullable cfg))done;
- (nullable HFParcelConfig *)hf_ledgerCache;
- (void)hf_ledgerWipe;
@end

NS_ASSUME_NONNULL_END
