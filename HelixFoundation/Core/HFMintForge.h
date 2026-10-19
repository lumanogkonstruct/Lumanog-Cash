#import "HFCanvasRoot.h"

NS_ASSUME_NONNULL_BEGIN

/// 36.1 — Add / Change Bank Account (stub shell; form TBD)
@interface HFMintForge : HFCanvasRoot
@property (nonatomic, assign) BOOL hf_forgeAddMode;
@property (nonatomic, copy, nullable) NSString *hf_recordId;
@property (nonatomic, copy, nullable) NSString *hf_defaultFlag;
@property (nonatomic, copy, nullable) NSString *hf_accountType;
@property (nonatomic, copy, nullable) NSString *hf_bankName;
@property (nonatomic, copy, nullable) NSString *hf_bankCode;
@property (nonatomic, copy, nullable) NSString *hf_accountNo;
@end

NS_ASSUME_NONNULL_END
