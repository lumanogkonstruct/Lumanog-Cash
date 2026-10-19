#import "HFPraiseGate.h"
#import "HFStarRail.h"
#import "HFCurtainBox.h"
#import "HFOrbitHint.h"
#import "HFVaultSeal.h"
#import "HFLedgerFetch.h"
#import "HFParcelModels.h"
#import <StoreKit/StoreKit.h>
#import <Masonry/Masonry.h>

// Design title + body; toast / thank copy from docs_phl/45.
static NSString * const kHFPraiseTitle = @"Rate";
static NSString * const kHFPraiseBody =
    @"We hope you grow with us. If you like our app, please support our work by giving us a five-star rating!";
static NSString * const kHFPraiseEmptyToast =
    @"Please rate our app first and we will keep improving based on your feedback!";
static NSString * const kHFThankTitle = @"Thank you";
static NSString * const kHFThankBody =
    @"We sincerely thank you for your feedback! We will carefully consider your suggestions to continuously improve.";

@interface HFPraiseGate ()
@property (nonatomic, strong, nullable) id hf_sheetToken;
@property (nonatomic, weak) HFStarRail *hf_rail;
@end

@implementation HFPraiseGate

+ (instancetype)shared {
    static HFPraiseGate *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFPraiseGate new];
    });
    return ins;
}

- (void)hf_praiseRememberKind:(NSInteger)userKind {
    if (userKind <= 0) return;
    [[NSUserDefaults standardUserDefaults] setInteger:userKind forKey:[HFVaultSeal kTauKindFlag]];
}

- (NSInteger)hf_praiseCachedKind {
    NSInteger k = [[NSUserDefaults standardUserDefaults] integerForKey:[HFVaultSeal kTauKindFlag]];
    return k > 0 ? k : 1;
}

- (BOOL)hf_praiseShownInstall {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[HFVaultSeal kSigmaRateFlag]];
}

- (void)hf_praiseMarkShown {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[HFVaultSeal kSigmaRateFlag]];
}

- (BOOL)hf_praiseAllowedForKind:(NSInteger)userKind {
    if ([self hf_praiseShownInstall]) return NO;
    HFParcelConfig *cfg = [[HFLedgerFetch shared] hf_ledgerCache];
    NSString *g = cfg.feedbackGuidance ?: @"";
    if (g.length == 0) return YES; // 45: missing config → show all
    NSInteger mode = g.integerValue;
    if (mode == 0) return NO;
    if (mode == 1) return YES;
    if (mode == 2) return userKind == 2;
    return YES;
}

- (void)hf_praiseTrySubmit:(void (^)(NSInteger))onSubmit cancel:(void (^)(void))onCancel {
    [self hf_praiseTryKind:[self hf_praiseCachedKind] submit:onSubmit cancel:onCancel];
}

- (void)hf_praiseTryKind:(NSInteger)userKind
                  submit:(void (^)(NSInteger))onSubmit
                  cancel:(void (^)(void))onCancel {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self hf_praiseAllowedForKind:userKind]) {
            if (onCancel) onCancel();
            return;
        }
        [self hf_praiseMarkShown];
        [self hf_praisePresentSubmit:onSubmit cancel:onCancel];
    });
}

- (void)hf_praisePresentSubmit:(void (^)(NSInteger))onSubmit cancel:(void (^)(void))onCancel {
    HFStarRail *rail = [HFStarRail new];
    rail.hf_starSide = 36;
    rail.hf_starGap = 12;
    self.hf_rail = rail;

    UIView *extra = [UIView new];
    [extra addSubview:rail];
    [rail mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(extra);
        make.centerX.equalTo(extra);
        make.height.mas_equalTo(36);
        make.width.mas_equalTo(36 * 5 + 12 * 4);
    }];

    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = kHFPraiseTitle;
    s.bodyText = kHFPraiseBody;
    s.extraView = extra;
    s.leftTitle = @"Cancel";
    s.rightTitle = @"Submit";
    s.autoCloseOnAction = NO;
    s.tier = HFCurtainTierMid;
    __weak typeof(self) weakSelf = self;
    s.onLeft = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self.hf_sheetToken) {
            [[HFCurtainBox shared] hf_curtainDismiss:self.hf_sheetToken];
            self.hf_sheetToken = nil;
        }
        if (onCancel) onCancel();
    };
    s.onRight = ^{
        __strong typeof(weakSelf) self = weakSelf;
        NSInteger score = self.hf_rail.hf_score;
        if (score <= 0) {
            [[HFOrbitHint shared] hf_orbitPulse:kHFPraiseEmptyToast];
            return;
        }
        if (self.hf_sheetToken) {
            [[HFCurtainBox shared] hf_curtainDismiss:self.hf_sheetToken];
            self.hf_sheetToken = nil;
        }
        if (score >= 4) {
            [self hf_praiseRequestStore];
            if (onSubmit) onSubmit(score);
            return;
        }
        [self hf_praiseThank:^{
            if (onSubmit) onSubmit(score);
        }];
    };
    self.hf_sheetToken = [[HFCurtainBox shared] hf_curtainSheet:s];
}

- (void)hf_praiseThank:(void (^)(void))onConfirm {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Design: Thank you + body + Cancel / Confirm (no icon).
        HFCurtainSheet *s = [HFCurtainSheet new];
        s.titleText = kHFThankTitle;
        s.bodyText = kHFThankBody;
        s.leftTitle = @"Cancel";
        s.rightTitle = @"Confirm";
        s.showClose = NO;
        s.tier = HFCurtainTierMid;
        s.onLeft = ^{};
        s.onRight = ^{
            if (onConfirm) onConfirm();
        };
        [[HFCurtainBox shared] hf_curtainSheet:s];
    });
}

- (void)hf_praiseRequestStore {
    UIWindowScene *scene = nil;
    for (UIScene *item in UIApplication.sharedApplication.connectedScenes) {
        if (![item isKindOfClass:[UIWindowScene class]]) continue;
        if (item.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)item;
            break;
        }
    }
    if (scene) {
        [SKStoreReviewController requestReviewInScene:scene];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [SKStoreReviewController requestReview];
#pragma clang diagnostic pop
    }
}

@end
