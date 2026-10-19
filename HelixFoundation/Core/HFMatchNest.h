#import "HFCanvasRoot.h"

NS_ASSUME_NONNULL_BEGIN

/// docs_phl/52 §3 — 精准推荐页：匹配弹窗 + dcRecommend → 产品申请 / 4102007拒量H5 / 其它错误
@interface HFMatchNest : HFCanvasRoot

@property (nonatomic, copy, nullable) NSString *hf_promptCopy;
@property (nonatomic, assign) NSInteger hf_userStatus;

@end

NS_ASSUME_NONNULL_END
