#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Module 07 — API / app constants (obfuscated identifiers; path literals unchanged)
@interface HFVaultSeal : NSObject

#pragma mark - App config values

+ (NSString *)kAlphaSeed;
+ (NSString *)kBetaGrain;
+ (NSString *)kGammaToken;
+ (NSString *)kDeltaRev;
+ (NSString *)kEpsilonLane;
+ (NSInteger)kZetaOSFlag;
+ (NSString *)kEtaTongue;
+ (NSString *)kThetaBizSlot;
+ (NSString *)kIotaBundleRev;

#pragma mark - Host / domain

+ (NSString *)kKappaBaseURL;

#pragma mark - Static H5 links (temporary; not from appConfig)

+ (NSString *)kHrefPrivacy;
+ (NSString *)kHrefAgreement;
+ (NSString *)kHrefLoanTerms;
+ (NSString *)kHrefContact;
+ (NSString *)kHrefKYC;
+ (NSString *)kHrefProductApply;
+ (NSString *)kHrefOrderDetails;
+ (NSString *)kHrefUpdateBank;
+ (NSString *)kHrefFeedback;
+ (NSString *)kHrefSuccess;

#pragma mark - Storage keys (obfuscated literals)

+ (NSString *)kXiUserSlot;
+ (NSString *)kOmicronGate;
+ (NSString *)kRhoFirstFlag;
+ (NSString *)kSigmaRateFlag;
+ (NSString *)kTauKindFlag;
+ (NSString *)kUpsilonSessionFlag;
+ (NSString *)kPhiCipherSvc;
+ (NSString *)kChiCipherAcctDF;
+ (NSString *)kPsiCipherAcctID;
+ (NSString *)kOmegaIdfaFlag;
+ (NSString *)kPhoneSlot;
+ (NSString *)kVisageSealAcct;
/// UserDefaults: set when this install saved a Face seal. Cleared on uninstall (Keychain is not).
+ (NSString *)kVisageSealFlag;

#pragma mark - H5 paths only

+ (NSString *)pAppConfig;
+ (NSString *)pVersionV2;
+ (NSString *)pMobileDevice;
+ (NSString *)pMobileContact;
+ (NSString *)pInstallApp;
+ (NSString *)pRegisterOrLogin;
+ (NSString *)pPwsLogin;
+ (NSString *)pSendVerifySms;
+ (NSString *)pSupHome;
+ (NSString *)pUserInfo;
+ (NSString *)pRegisterDevice;
+ (NSString *)pProductTermV3;
+ (NSString *)pProductList;
+ (NSString *)pDcRecommend;
+ (NSString *)pOrderReady;
+ (NSString *)pOrderList;
+ (NSString *)pKycFourStatus;
+ (NSString *)pAuthClose;
+ (NSString *)pBuryRecord;
+ (NSString *)pPayAccountList;
+ (NSString *)pPayAccountUpdate;

#pragma mark - Error / status codes

+ (NSString *)eTokenExpired;
+ (NSString *)eTokenInvalid;
+ (NSString *)eUserMissing;
+ (NSString *)eForceUpdate;
+ (NSString *)eDcNoProduct;
+ (NSInteger)sPendingKYC;
+ (NSInteger)sPendingPayout;
+ (NSInteger)sNeedExtra;
+ (NSInteger)sPendingWithdraw;
+ (NSInteger)sNeedBankFix;
+ (NSInteger)sReviewing;
+ (NSInteger)sRejected;
+ (NSInteger)sPaying;
+ (NSInteger)sRepaying;
+ (NSInteger)sOverdue;

#pragma mark - Decoy surface (unused by business)

+ (NSString *)hf_qxNoiseAlpha;
+ (NSString *)hf_qxNoiseBeta;
+ (NSString *)hf_qxNoiseGamma;
+ (NSString *)hf_qxNoiseDelta;
+ (NSString *)hf_qxNoiseEpsilon;
+ (NSString *)hf_qxNoiseZeta;
+ (NSString *)hf_qxNoiseEta;
+ (NSString *)hf_qxNoiseTheta;
+ (NSString *)hf_qxNoiseIota;
+ (NSString *)hf_qxNoiseKappa;
+ (NSArray<NSString *> *)hf_qxNoiseLaneList;
+ (NSDictionary *)hf_qxNoiseLedger;
+ (NSInteger)hf_qxNoisePrime:(NSInteger)seed;
+ (NSString *)hf_qxNoiseMix:(NSString *)a trail:(NSString *)b;
+ (BOOL)hf_qxNoiseProbe:(NSString *)token;
+ (NSData *)hf_qxNoiseBlob:(NSUInteger)size;
+ (NSString *)hf_qxNoiseShard:(NSInteger)idx;
+ (NSArray<NSNumber *> *)hf_qxNoiseWeights;
+ (NSString *)hf_qxNoiseRouteA;
+ (NSString *)hf_qxNoiseRouteB;
+ (NSString *)hf_qxNoiseRouteC;
+ (NSString *)hf_qxNoiseRouteD;
+ (NSString *)hf_qxNoiseRouteE;
+ (NSString *)hf_qxNoiseRouteF;
+ (NSString *)hf_qxNoiseRouteG;
+ (NSString *)hf_qxNoiseRouteH;
+ (NSString *)hf_qxNoiseVaultKey;
+ (NSString *)hf_qxNoiseMirrorKey;
+ (NSString *)hf_qxNoiseShadowKey;
+ (NSString *)hf_qxNoiseDriftKey;
+ (NSInteger)hf_qxNoiseEpoch;
+ (NSInteger)hf_qxNoiseSalt;
+ (double)hf_qxNoiseRatio;
+ (NSString *)hf_qxNoiseDigest:(NSString *)raw;
+ (NSArray *)hf_qxNoiseMatrix;
+ (void)hf_qxNoiseWarm;
+ (BOOL)hf_qxNoiseArmed;
+ (NSString *)hf_qxNoiseFence;
+ (NSString *)hf_qxNoiseHarbor;
+ (NSString *)hf_qxNoiseOrbit;
+ (NSString *)hf_qxNoiseLattice;
+ (NSString *)hf_qxNoiseParcel;
+ (NSString *)hf_qxNoiseQuill;
+ (NSString *)hf_qxNoiseRelay;
+ (NSString *)hf_qxNoiseCipher;
+ (NSDictionary *)hf_qxNoiseManifest;
+ (NSString *)hf_qxNoiseAlias:(NSInteger)slot;

@end

NS_ASSUME_NONNULL_END
