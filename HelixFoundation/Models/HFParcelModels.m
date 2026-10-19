#import "HFParcelModels.h"
#import <YYModel/YYModel.h>

@implementation HFParcelDynParam
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"fjtip": @"pelkcat",
    };
}
@end

@implementation HFParcelConfig
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"dynamicParameter": @"dywogpe",
        @"hotline": @"escape",
        @"appEmail": @"nowadays",
        @"attributionTimeout": @"skillful",
        @"officialWebsiteUrl": @"musical",
        @"conditionsHref": @"leap",
        @"agreementHref": @"furthermore",
        @"policyHref": @"get",
        @"authHref": @"prisoner",
        @"qaHref": @"earn",
        @"contactHref": @"insure",
        @"aboutHref": @"rust",
        @"desireHref": @"boundary",
        @"buryChannel": @"image",
        @"livenessDetectionMethod": @"livenessDetectionMethod",
        @"livenessDetectionProvider": @"livenessDetectionProvider",
        @"pushPerCount": @"capacity",
        @"pushMaxCount": @"term",
        @"reloanSelfCheckType": @"shortly",
        @"firstLoanOptionLine": @"either",
        @"customerRating": @"pulse", // newCustomerRating
        @"isUpdateUserInfo": @"isUpdateUserInfo",
        @"countryCode": @"youth",
        @"currencySymbol": @"brow",
        @"isThirdAthena": @"photo",
        @"retrieveMobileContact": @"purpose",
        @"voiceAuth": @"voiceAuth",
        @"appStatus": @"generally",
        @"kycLink": @"chill",
        @"productApplyLink": @"puzzle",
        @"orderDetailsLink": @"laugh",
        @"problemFeedbackLink": @"criticism",
        @"updateBankLink": @"yearly",
        @"applicationSuccessLink": @"festival",
        @"bankCardInfoLink": @"cash",
        @"aboutUsLink": @"hello",
        @"feedbackGuidance": @"lay",
        @"h5ZipUrl": @"lorry",
    };
}
@end

@implementation HFParcelVersion
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"latestVersion": @"latestVersion",
        @"latestVersionUrl": @"voltage",
        @"latestVersionContent": @"characteristi",

    };
}
@end

@implementation HFParcelLogin
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"userId": @"detection",
        @"token": @"spur",
        @"isRegister": @"education",
        @"password": @"password",
    };
}
@end

@implementation HFParcelUser
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"desire": @"summary",
        @"phone": @"guide",
        @"userStatus": @"farmer",
        @"payAccountModifySwitch": @"build",
        @"smsSwitch": @"guarantee",
        @"existsMobileContact": @"for",
        @"appUserType": @"logical",
        @"name": @"instruct",
    };
}
@end

@implementation HFParcelBanner
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"bannerHref": @"spray",
        @"relationId": @"expectation",
    };
}
@end

@implementation HFParcelOrderCount
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"orderId": @"substantial",
        @"orderStatus": @"incident",
        @"productId": @"resistance",
        @"label": @"conquer",
    };
}
@end

@implementation HFParcelHome
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"userStatus": @"farmer",
        @"appUserType": @"logical",
        @"hasOrder": @"vague",
        @"firstLoanOptionLine": @"either",
        @"loanSuccessRecordList": @"hire",
        @"appProductBanner": @"jet",
        @"appLabelBanner": @"lung",
        @"promptCopy": @"fog",
        @"maxApplyAmount": @"maxApplyAmount",
        @"downloadUrl": @"ought",
        @"withdrawalOrderId": @[@"news", @"currentOrderId", @"withdrawalOrderId"],

        @"orderStatusCount": @[@"subway", @"orderDetail", @"orderStatusCount"],
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"loanSuccessRecordList": [NSString class],
        @"appProductBanner": [HFParcelBanner class],
        @"appLabelBanner": [HFParcelBanner class],
        @"orderStatusCount": [HFParcelOrderCount class],
    };
}
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id raw = dic[@"maxApplyAmount"];
    if ([raw isKindOfClass:[NSNumber class]]) {
        self.maxApplyAmount = [(NSNumber *)raw stringValue];
    } else if ([raw isKindOfClass:[NSString class]]) {
        self.maxApplyAmount = (NSString *)raw;
    }
    return YES;
}
@end

@implementation HFParcelLabelItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"labelId": @[@"specify", @"labelId"],
        @"labelName": @[@"comment", @"labelName"],
    };
}
@end

@implementation HFParcelProductInfo
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"highAmount": @[@"ghost", @"highAmount"],
        @"highestTerm": @[@"tolerance", @"highestTerm"],
        @"loanAmount": @[@"chalk", @"loanAmount"],
        @"lowAmount": @[@"undergo", @"lowAmount"],
        @"lowestLoanInterestRate": @[@"interest", @"lowestLoanInterestRate"],
        @"productApplicantsNumber": @[@"occasional", @"productApplicantsNumber"],
        @"productId": @[@"resistance", @"productId"],
        @"productLabel": @[@"horror", @"productLabel"],
        @"productLabelList": @[@"toast", @"productLabelList"],
        @"productLogo": @[@"green", @"productLogo"],
        @"productName": @[@"seize", @"productName"],
        // lastOrderId / lastOrderStatus / productTermV3Response: clear keys (dcRecommend)
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"productLabelList": [HFParcelLabelItem class],
        @"productTermV3Response": [HFParcelProductTerm class],
    };
}
@end

@implementation HFParcelProductList
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"productInfoList": @[@"portion", @"productInfoList"],
        @"productLabelList": @[@"toast", @"productLabelList"],
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"amountList": [NSNumber class],
        @"productInfoList": [HFParcelProductInfo class],
        @"productLabelList": [HFParcelLabelItem class]
    };
}
@end

@implementation HFParcelReloanItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"loanAmount": @"chalk",
        @"productId": @"resistance",
        @"productLogo": @"green",
        @"productName": @"seize",
    };
}
@end

@implementation HFParcelProductState
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"amountDetailList": @"expand",
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"amountDetailList": [HFParcelReloanItem class] };
}
@end

@implementation HFParcelTermItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"interestAmountDue": @"necessity",
        @"expirationDate": @"sample",
        @"repaymentAmount": @"indispensable",
        @"principalAmountDue": @"gather",
    };
}
@end

@implementation HFParcelTermDetail
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"loanTerm": @"culture",
        @"showTerm": @"violet",
        @"productTermUnit": @"community",
        @"feeAmount": @"rod",
        @"taxAmount": @"transformer",
        @"arrivalAmount": @"cancel",
        @"interestAmount": @"philosophy",
        @"repaymentAmount": @"indispensable",
        @"borrowingDate": @"postage",
        @"repaymentDate": @"establish",
        @"EMITenure": @"liberate",
        @"EMIAmount": @"explosion",
        @"productTermItemList": @"encourage",
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"productTermItemList": [HFParcelTermItem class] };
}
@end

@implementation HFParcelAmountDetail
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"loanAmount": @"chalk",
        @"termDetailList": @"empty",
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"termDetailList": [HFParcelTermDetail class] };
}
@end

@implementation HFParcelCardInfo
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"bindId": @"film",
        @"accountType": @"bright",
        @"bankCode": @"eight",
        @"bankName": @"expense",
        @"accountNo": @"accountNo",
        @"accountName": @"water",
        @"accountPhone": @"transfer",
        @"currency": @"prosperous",
    };
}
@end

@implementation HFParcelPayAccount
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"accountType": @"bright",
        @"bankCode": @"eight",
        @"bankName": @"expense",
        @"accountNo": @"accountNo",
        @"accountName": @"water",

    };
}
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id bind = dic[@"bankCardBindId"];
    if (!bind) bind = dic[@"film"]; // bindId
    if ([bind isKindOfClass:[NSNumber class]]) {
        self.bankCardBindId = [(NSNumber *)bind stringValue];
    } else if ([bind isKindOfClass:[NSString class]]) {
        self.bankCardBindId = (NSString *)bind;
    }
    id rid = dic[@"recordId"];
    if ([rid isKindOfClass:[NSNumber class]]) {
        self.recordId = [(NSNumber *)rid stringValue];
    } else if ([rid isKindOfClass:[NSString class]]) {
        self.recordId = (NSString *)rid;
    }
    return YES;
}
@end

@implementation HFParcelPayAccountList
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"payAccountInfoList": [HFParcelPayAccount class] };
}
@end

@implementation HFParcelProductTerm
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"productId": @"resistance",
        @"productName": @"seize",
        @"productLogo": @"green",
        @"productTermUnit": @"community",
        @"productHotline": @"mist",
        @"amountDetailList": @"expand",
        @"bankCardList": @"external",
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"amountDetailList": [HFParcelAmountDetail class],
        @"bankCardList": [HFParcelCardInfo class]
    };
}
@end

@implementation HFParcelOrderItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"applyDate": @"applyDate",
        @"dueDate": @"recently",
        @"loanAmount": @"chalk",
        @"loanDate": @"resume",
        @"orderId": @"substantial",
        @"orderStatus": @"incident",
        @"productId": @"resistance",
        @"productName": @"seize",
        @"repayDate": @"singular",
        @"userId": @"detection",
    };
}
@end

@implementation HFParcelOrderList
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"orderList": @"merely",
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"orderList": [HFParcelOrderItem class] };
}
@end

@implementation HFParcelKycStatus
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"echoMap": @"grip",
    };
}
- (NSString *)hf_willExecuteStep {
    id v = self.echoMap[@"willExecuteStepNumber"];
    if ([v isKindOfClass:[NSString class]]) return (NSString *)v;
    if ([v isKindOfClass:[NSNumber class]]) return [(NSNumber *)v stringValue];
    return @"";
}
@end

@implementation HFParcelConfigReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelConfig class] };
}
@end

@implementation HFParcelVersionReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelVersion class] };
}
@end

@implementation HFParcelLoginReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelLogin class] };
}
@end

@implementation HFParcelSmsHint
@end

@implementation HFParcelSmsHintReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelSmsHint class] };
}
@end

@implementation HFParcelUserReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelUser class] };
}
@end

@implementation HFParcelHomeReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelHome class] };
}
@end

@implementation HFParcelProductListReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelProductList class] };
}
@end

@implementation HFParcelProductStateReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelProductState class] };
}
@end

@implementation HFParcelProductTermReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelProductTerm class] };
}
@end

@implementation HFParcelOrderSeed
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"orderId": @"substantial",
    };
}
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id oid = dic[@"substantial"];
    if ([oid isKindOfClass:[NSNumber class]]) {
        self.orderId = [(NSNumber *)oid stringValue];
    } else if ([oid isKindOfClass:[NSString class]]) {
        self.orderId = (NSString *)oid;
    }
    return YES;
}
@end

@implementation HFParcelOrderSeedReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelOrderSeed class] };
}
@end

@implementation HFParcelPayAccountListReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelPayAccountList class] };
}
@end

@implementation HFParcelOrderListReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelOrderList class] };
}
@end

@implementation HFParcelDcRecommendReply
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{ @"data": [HFParcelProductList class] };
}
@end
