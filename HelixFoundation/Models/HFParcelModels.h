#import <Foundation/Foundation.h>
#import "HFParcelBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface HFParcelDynParam : NSObject
@property (nonatomic, copy) NSString *fjtip;
@property (nonatomic, copy) NSString *contactCount;
@property (nonatomic, copy) NSString *invite_url;
@property (nonatomic, copy) NSString *invite_switch;
@property (nonatomic, copy) NSString *AIService;
@property (nonatomic, copy) NSString *customerH5;
@property (nonatomic, copy) NSString *rejectH5;
@end

@interface HFParcelConfig : NSObject
@property (nonatomic, strong, nullable) HFParcelDynParam *dynamicParameter;
@property (nonatomic, copy) NSString *hotline;
@property (nonatomic, copy) NSString *appEmail;
@property (nonatomic, assign) NSInteger attributionTimeout;
@property (nonatomic, copy) NSString *officialWebsiteUrl;
@property (nonatomic, copy) NSString *conditionsHref;
@property (nonatomic, copy) NSString *agreementHref;
@property (nonatomic, copy) NSString *policyHref;
@property (nonatomic, copy) NSString *authHref;
@property (nonatomic, copy) NSString *qaHref;
@property (nonatomic, copy) NSString *contactHref;
@property (nonatomic, copy) NSString *aboutHref;
@property (nonatomic, copy) NSString *desireHref;
@property (nonatomic, copy) NSString *buryChannel;
@property (nonatomic, copy) NSString *livenessDetectionMethod;
@property (nonatomic, copy) NSString *livenessDetectionProvider;
@property (nonatomic, assign) NSInteger pushPerCount;
@property (nonatomic, assign) NSInteger pushMaxCount;
@property (nonatomic, copy) NSString *reloanSelfCheckType;
@property (nonatomic, copy) NSString *firstLoanOptionLine;
@property (nonatomic, copy) NSString *customerRating;
@property (nonatomic, assign) NSInteger isUpdateUserInfo;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *currencySymbol;
@property (nonatomic, assign) NSInteger isThirdAthena;
@property (nonatomic, assign) NSInteger retrieveMobileContact;
@property (nonatomic, copy) NSString *voiceAuth;
@property (nonatomic, assign) NSInteger appStatus;
@property (nonatomic, copy) NSString *kycLink;
@property (nonatomic, copy) NSString *productApplyLink;
@property (nonatomic, copy) NSString *orderDetailsLink;
@property (nonatomic, copy) NSString *problemFeedbackLink;
@property (nonatomic, copy) NSString *updateBankLink;
@property (nonatomic, copy) NSString *applicationSuccessLink;
@property (nonatomic, copy) NSString *bankCardInfoLink;
@property (nonatomic, copy) NSString *aboutUsLink;
@property (nonatomic, copy) NSString *feedbackGuidance;
@property (nonatomic, copy) NSString *h5ZipUrl;
@end

@interface HFParcelVersion : NSObject
@property (nonatomic, copy) NSString *latestVersion;
@property (nonatomic, copy) NSString *latestVersionUrl;
@property (nonatomic, copy) NSString *latestVersionContent;
@property (nonatomic, copy) NSString *updateType;
@end

@interface HFParcelLogin : NSObject
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, assign) BOOL isRegister;
@end

@interface HFParcelSmsHint : NSObject
@property (nonatomic, copy) NSString *sendTip;
@property (nonatomic, strong, nullable) id sendMode;
@end

@interface HFParcelUser : NSObject
@property (nonatomic, copy) NSString *reason;
@property (nonatomic, assign) NSInteger desire;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, assign) NSInteger userStatus;
@property (nonatomic, copy) NSString *payAccountModifySwitch;
@property (nonatomic, copy) NSString *smsSwitch;
@property (nonatomic, copy) NSString *existsMobileContact;
@property (nonatomic, assign) NSInteger appUserType;
@property (nonatomic, copy) NSString *name;
@end

@interface HFParcelBanner : NSObject
@property (nonatomic, copy) NSString *bannerHref;
@property (nonatomic, copy) NSString *relationId;
@end

@interface HFParcelOrderCount : NSObject
@property (nonatomic, assign) NSInteger settleOrderCount;
@property (nonatomic, assign) NSInteger repaymentOrderCount;
@property (nonatomic, assign) NSInteger payoutOrderCount;
@property (nonatomic, assign) NSInteger approveOrderCount;
@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, copy) NSString *orderStatus;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *label;
@end

@interface HFParcelHome : NSObject
@property (nonatomic, assign) NSInteger userStatus;
@property (nonatomic, assign) NSInteger appUserType;
@property (nonatomic, assign) NSInteger hasOrder;
@property (nonatomic, copy) NSString *firstLoanOptionLine;
@property (nonatomic, strong) NSArray<NSString *> *loanSuccessRecordList;
@property (nonatomic, strong) NSArray<HFParcelBanner *> *appProductBanner;
@property (nonatomic, strong) NSArray<HFParcelBanner *> *appLabelBanner;
@property (nonatomic, copy) NSString *promptCopy;
@property (nonatomic, copy) NSString *maxApplyAmount;
@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, copy) NSString *withdrawalOrderId;
@property (nonatomic, strong, nullable) HFParcelOrderCount *orderStatusCount;
@end

@interface HFParcelLabelItem : NSObject
@property (nonatomic, copy) NSString *labelId;
@property (nonatomic, copy) NSString *labelName;
@end

@class HFParcelProductTerm;

@interface HFParcelProductInfo : NSObject
@property (nonatomic, assign) NSInteger companyId;
@property (nonatomic, assign) NSInteger defaultLoanDayInterestRate;
@property (nonatomic, assign) NSInteger defaultLoanTerm;
@property (nonatomic, assign) NSInteger defaultTaxRate;
@property (nonatomic, copy) NSString *highAmount;
@property (nonatomic, copy) NSString *highestTerm;
@property (nonatomic, copy) NSString *loanAmount;
@property (nonatomic, copy) NSString *lowAmount;
@property (nonatomic, copy) NSString *lowestLoanInterestRate;
@property (nonatomic, assign) NSInteger nature;
@property (nonatomic, copy) NSString *partnerId;
@property (nonatomic, copy) NSString *productApplicantsNumber;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *productLabel;
@property (nonatomic, strong) NSArray<HFParcelLabelItem *> *productLabelList;
@property (nonatomic, copy) NSString *productLogo;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, assign) NSInteger productType;
@property (nonatomic, copy) NSString *reloanAmount;

@property (nonatomic, copy) NSString *lastOrderId;
@property (nonatomic, copy) NSString *lastOrderStatus;
/// dcRecommend 嵌套 term（JSON key 仍为 `productTermV3Response`，未混淆）
@property (nonatomic, strong, nullable) HFParcelProductTerm *productTermV3Response;
@end

@interface HFParcelProductList : NSObject
@property (nonatomic, strong) NSArray<NSNumber *> *amountList;
@property (nonatomic, strong) NSArray<HFParcelProductInfo *> *productInfoList;
@property (nonatomic, strong) NSArray<HFParcelLabelItem *> *productLabelList;
@end

@interface HFParcelReloanItem : NSObject
@property (nonatomic, copy) NSString *loanAmount;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *productLogo;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, assign) NSInteger userType;
@end

@interface HFParcelProductState : NSObject
@property (nonatomic, strong) NSArray<HFParcelReloanItem *> *amountDetailList;
@end

@interface HFParcelTermItem : NSObject
@property (nonatomic, copy) NSString *interestAmountDue;
@property (nonatomic, copy) NSString *expirationDate;
@property (nonatomic, copy) NSString *repaymentAmount;
@property (nonatomic, copy) NSString *principalAmountDue;
@end

@interface HFParcelTermDetail : NSObject
@property (nonatomic, assign) NSInteger loanTerm;
@property (nonatomic, assign) NSInteger showTerm;
@property (nonatomic, assign) NSInteger productTermUnit;
@property (nonatomic, copy) NSString *feeAmount;
@property (nonatomic, copy) NSString *taxAmount;
@property (nonatomic, copy) NSString *arrivalAmount;
@property (nonatomic, copy) NSString *interestAmount;
@property (nonatomic, copy) NSString *repaymentAmount;
@property (nonatomic, copy) NSString *borrowingDate;
@property (nonatomic, copy) NSString *repaymentDate;
@property (nonatomic, assign) double loanDayInterestRate;
@property (nonatomic, assign) NSInteger EMITenure;
@property (nonatomic, assign) NSInteger EMIs;
@property (nonatomic, copy) NSString *EMIAmount;
@property (nonatomic, copy) NSString *EMIRepayDate;
@property (nonatomic, strong) NSArray<HFParcelTermItem *> *productTermItemList;
@end

@interface HFParcelAmountDetail : NSObject
@property (nonatomic, copy) NSString *loanAmount;
@property (nonatomic, strong) NSArray<HFParcelTermDetail *> *termDetailList;
@end

@interface HFParcelCardInfo : NSObject
@property (nonatomic, copy) NSString *bindId;
@property (nonatomic, copy) NSString *accountType;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *accountNo;
@property (nonatomic, copy) NSString *accountName;
@property (nonatomic, copy) NSString *accountPhone;
@property (nonatomic, copy) NSString *currency;
@end

@interface HFParcelPayAccount : NSObject
@property (nonatomic, copy) NSString *recordId;
@property (nonatomic, copy) NSString *bankCardBindId;
@property (nonatomic, copy) NSString *accountType;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *accountNo;
@property (nonatomic, copy) NSString *accountName;
@property (nonatomic, copy) NSString *defaultFlag;
@property (nonatomic, copy) NSString *editFlag;
@end

@interface HFParcelPayAccountList : NSObject
@property (nonatomic, strong) NSArray<HFParcelPayAccount *> *payAccountInfoList;
@end

@interface HFParcelProductTerm : NSObject
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, copy) NSString *productLogo;
@property (nonatomic, assign) NSInteger productTermUnit;
@property (nonatomic, copy) NSString *productHotline;
@property (nonatomic, strong) NSArray<HFParcelAmountDetail *> *amountDetailList;
@property (nonatomic, strong) NSArray<HFParcelCardInfo *> *bankCardList;
@property (nonatomic, copy) NSString *message;
@end

@interface HFParcelOrderItem : NSObject
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *applyDate;
@property (nonatomic, assign) NSInteger companyId;
@property (nonatomic, copy) NSString *dueDate;
@property (nonatomic, assign) NSInteger loanAmount;
@property (nonatomic, copy) NSString *loanDate;
@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, assign) NSInteger orderStatus;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, copy) NSString *repayDate;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *rejectH5;
@end

@interface HFParcelOrderList : NSObject
@property (nonatomic, strong) NSArray<HFParcelOrderItem *> *orderList;
@end

@interface HFParcelKycStatus : NSObject
@property (nonatomic, strong) NSDictionary *echoMap;
- (NSString *)hf_willExecuteStep;
@end

/// Full response wrappers — parse whole body via Model, typed `data`.
@interface HFParcelConfigReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelConfig *data;
@end

@interface HFParcelVersionReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelVersion *data;
@end

@interface HFParcelLoginReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelLogin *data;
@end

@interface HFParcelSmsHintReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelSmsHint *data;
@end

@interface HFParcelUserReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelUser *data;
@end

@interface HFParcelHomeReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelHome *data;
@end

@interface HFParcelProductListReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelProductList *data;
@end

@interface HFParcelProductStateReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelProductState *data;
@end

@interface HFParcelProductTermReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelProductTerm *data;
@end

/// autoOrderApply / userSubmitV3 — data.orderId
@interface HFParcelOrderSeed : NSObject
@property (nonatomic, copy) NSString *orderId;
@end

@interface HFParcelOrderSeedReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelOrderSeed *data;
@end

@interface HFParcelPayAccountListReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelPayAccountList *data;
@end

@interface HFParcelOrderListReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelOrderList *data;
@end

@interface HFParcelDcRecommendReply : HFParcelBase
@property (nonatomic, strong, nullable) HFParcelProductList *data;
@end

NS_ASSUME_NONNULL_END
