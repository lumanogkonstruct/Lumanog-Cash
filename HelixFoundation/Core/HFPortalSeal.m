#import "HFPortalSeal.h"
#import "HFPortalGate.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFQuillVault.h"
#import "HFProbeAtlas.h"
#import "HFLedgerFetch.h"
#import "HFPaneBrowse.h"
#import "HFTraceMark.h"
#import "HFPermitVeil.h"
#import "HFParcelModels.h"
#import "HFVisageLock.h"
#import "SceneDelegate.h"
#import <Masonry/Masonry.h>

static NSString * const kHFLinkPrivacy = @"hf-portal://privacy";
static NSString * const kHFLinkTerms = @"hf-portal://terms";
static const NSTimeInterval kHFPushDebounce = 0.8;
static BOOL sHFVisageSheetShown = NO;

@interface HFPortalSeal () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) UIView *hf_band;
@property (nonatomic, strong) UIImageView *hf_mark;
@property (nonatomic, strong) UILabel *hf_brand;
@property (nonatomic, strong) UIView *hf_phoneCard;
@property (nonatomic, strong) UILabel *hf_phoneCaption;
@property (nonatomic, strong) UILabel *hf_dial;
@property (nonatomic, strong) UITextField *hf_phoneField;
@property (nonatomic, strong) UIButton *hf_checkBtn;
@property (nonatomic, strong) UITextView *hf_agreeView;
@property (nonatomic, strong) UIButton *hf_enterBtn;
@property (nonatomic, assign) BOOL hf_agreed;
@property (nonatomic, assign) BOOL hf_enterBusy;
@property (nonatomic, assign) NSTimeInterval hf_lastPushAt;
@end

@implementation HFPortalSeal

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"";
    self.hf_agreed = YES;
    [self hf_buildChrome];
    [self hf_bindActions];
    [[HFLedgerFetch shared] hf_ledgerObtain:^(__unused HFParcelConfig *cfg) {}];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - UI

- (void)hf_buildChrome {
    self.hf_band = [UIView new];
    self.hf_band.backgroundColor = [UIColor hf_prismTheme];
    [self.view addSubview:self.hf_band];

    UIView *brandRow = [UIView new];
    [self.hf_band addSubview:brandRow];

    self.hf_mark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.hf_mark.contentMode = UIViewContentModeScaleAspectFit;
    self.hf_mark.layer.cornerRadius = 12;
    self.hf_mark.clipsToBounds = YES;
    [brandRow addSubview:self.hf_mark];

    self.hf_brand = [UILabel new];
    self.hf_brand.text = [self hf_displayName];
    self.hf_brand.textColor = [UIColor hf_prismHex:@"#3A2A1F"];
    self.hf_brand.font = [UIFont hf_latticeGlyph:24 mass:UIFontWeightRegular];
    [brandRow addSubview:self.hf_brand];

    self.hf_phoneCard = [self hf_cardShell];
    self.hf_phoneCaption = [self hf_fieldCaption:@"Mobile number"];
    self.hf_dial = [UILabel new];
    self.hf_dial.text = @"+63";
    self.hf_dial.textColor = [UIColor hf_prismTheme];
    self.hf_dial.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightMedium];
    self.hf_phoneField = [self hf_field:@"Please enter" keyboard:UIKeyboardTypeNumberPad];
    self.hf_phoneField.textAlignment = NSTextAlignmentLeft;
    self.hf_phoneField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.hf_phoneCard addSubview:self.hf_phoneCaption];
    [self.hf_phoneCard addSubview:self.hf_dial];
    [self.hf_phoneCard addSubview:self.hf_phoneField];
    [self.view addSubview:self.hf_phoneCard];

    self.hf_checkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.hf_checkBtn setImage:[UIImage imageNamed:@"make_icon_sel"] forState:UIControlStateNormal];
    [self.view addSubview:self.hf_checkBtn];

    self.hf_agreeView = [UITextView new];
    self.hf_agreeView.backgroundColor = UIColor.clearColor;
    self.hf_agreeView.editable = NO;
    self.hf_agreeView.scrollEnabled = NO;
    self.hf_agreeView.textContainerInset = UIEdgeInsetsZero;
    self.hf_agreeView.textContainer.lineFragmentPadding = 0;
    self.hf_agreeView.delegate = self;
    self.hf_agreeView.linkTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor hf_prismTheme],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    self.hf_agreeView.attributedText = [self hf_agreeAttr];
    [self.view addSubview:self.hf_agreeView];

    self.hf_enterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hf_enterBtn.backgroundColor = [UIColor hf_prismTheme];
    self.hf_enterBtn.layer.cornerRadius = 28;
    [self.hf_enterBtn setTitle:@"Sign in" forState:UIControlStateNormal];
    [self.hf_enterBtn setTitleColor:[UIColor hf_prismHex:@"#3A2A1F"] forState:UIControlStateNormal];
    self.hf_enterBtn.titleLabel.font = [UIFont hf_latticeGlyph:18 mass:UIFontWeightRegular];
    [self.view addSubview:self.hf_enterBtn];

    [self.hf_band mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.equalTo(self.view.mas_height).multipliedBy(0.32);
    }];
    [brandRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.hf_band);
        make.centerY.equalTo(self.hf_band).offset(10);
    }];
    [self.hf_mark mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(brandRow);
        make.width.height.mas_equalTo(48);
    }];
    [self.hf_brand mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_mark.mas_trailing).offset(12);
        make.trailing.equalTo(brandRow);
        make.centerY.equalTo(self.hf_mark);
    }];

    [self.hf_phoneCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_band.mas_bottom).offset(28);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];
    [self.hf_phoneCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_phoneCard).offset(14);
        make.leading.equalTo(self.hf_phoneCard).offset(16);
        make.trailing.equalTo(self.hf_phoneCard).offset(-16);
    }];
    [self.hf_dial mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_phoneCaption);
        make.top.equalTo(self.hf_phoneCaption.mas_bottom).offset(10);
        make.bottom.equalTo(self.hf_phoneCard).offset(-16);
    }];
    [self.hf_dial setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.hf_phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_dial.mas_trailing).offset(8);
        make.centerY.equalTo(self.hf_dial);
        make.trailing.equalTo(self.hf_phoneCard).offset(-16);
        make.height.mas_equalTo(24);
    }];

    [self.hf_enterBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(56);
    }];
    [self.hf_agreeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_checkBtn.mas_trailing).offset(8);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.hf_enterBtn.mas_top).offset(-18);
    }];
    [self.hf_checkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.top.equalTo(self.hf_agreeView).offset(2);
        make.width.height.mas_equalTo(22);
    }];
}

- (UIView *)hf_cardShell {
    UIView *v = [UIView new];
    v.backgroundColor = UIColor.whiteColor;
    v.layer.cornerRadius = 16;
    return v;
}

- (UILabel *)hf_fieldCaption:(NSString *)text {
    UILabel *l = [UILabel new];
    l.text = text;
    l.textColor = [UIColor hf_prismHex:@"#666666"];
    l.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    return l;
}

- (UITextField *)hf_field:(NSString *)placeholder keyboard:(UIKeyboardType)kb {
    UITextField *f = [UITextField new];
    f.placeholder = placeholder;
    f.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightRegular];
    f.textColor = [UIColor hf_prismHex:@"#333333"];
    f.keyboardType = kb;
    f.delegate = self;
    f.autocorrectionType = UITextAutocorrectionTypeNo;
    f.autocapitalizationType = UITextAutocapitalizationTypeNone;
    return f;
}

- (NSString *)hf_displayName {
    NSString *n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!n.length) n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return n.length ? n : @"appname";
}

- (NSAttributedString *)hf_agreeAttr {
    NSString *full = @"Please read and accept Privacy policy and Service agreement";
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSFontAttributeName: [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular],
        NSForegroundColorAttributeName: [UIColor hf_prismHex:@"#666666"]
    }];
    NSRange p = [full rangeOfString:@"Privacy policy"];
    NSRange t = [full rangeOfString:@"Service agreement"];
    if (p.location != NSNotFound) {
        [m addAttribute:NSLinkAttributeName value:kHFLinkPrivacy range:p];
        [m addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:p];
        [m addAttribute:NSForegroundColorAttributeName value:[UIColor hf_prismTheme] range:p];
    }
    if (t.location != NSNotFound) {
        [m addAttribute:NSLinkAttributeName value:kHFLinkTerms range:t];
        [m addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:t];
        [m addAttribute:NSForegroundColorAttributeName value:[UIColor hf_prismTheme] range:t];
    }
    return m;
}

- (void)hf_bindActions {
    [self.hf_enterBtn addTarget:self action:@selector(hf_tapEnter) forControlEvents:UIControlEventTouchUpInside];
    [self.hf_checkBtn addTarget:self action:@selector(hf_tapCheck) forControlEvents:UIControlEventTouchUpInside];
    [self.hf_phoneField addTarget:self action:@selector(hf_phoneEdited:) forControlEvents:UIControlEventEditingChanged];
}

#pragma mark - Input filter

- (NSString *)hf_onlyDigits:(NSString *)raw {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) return @"";
    return [[raw componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

- (NSString *)hf_phoneClamp:(NSString *)raw {
    NSString *d = [self hf_onlyDigits:raw];
    if (d.length == 0) return @"";
    if ([d hasPrefix:@"630"]) {
        d = [d substringFromIndex:2];
    } else if ([d hasPrefix:@"63"]) {
        d = [d substringFromIndex:2];
    }
    unichar c0 = [d characterAtIndex:0];
    if (c0 != '0' && c0 != '9') return @"";
    if (c0 == '0') {
        if (d.length >= 2 && [d characterAtIndex:1] != '9') {
            return @"0";
        }
        if (d.length > 11) d = [d substringToIndex:11];
    } else {
        if (d.length > 10) d = [d substringToIndex:10];
    }
    return d;
}

- (void)hf_phoneEdited:(UITextField *)field {
    NSString *d = [self hf_phoneClamp:field.text];
    if (![field.text isEqualToString:d]) field.text = d;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length == 0) return YES;
    NSString *cur = textField.text ?: @"";
    if (NSMaxRange(range) > cur.length) return NO;
    if (textField == self.hf_phoneField) {
        NSString *proposed = [cur stringByReplacingCharactersInRange:range withString:string];
        NSString *clamped = [self hf_phoneClamp:proposed];
        if ([clamped isEqualToString:proposed]) return YES;
        textField.text = clamped;
        return NO;
    }
    return YES;
}

#pragma mark - Phone rules

- (BOOL)hf_phoneLooksValid:(NSString *)digits {
    if (!digits.length) return NO;
    NSPredicate *p = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^(9\\d{9}|09\\d{9})$"];
    return [p evaluateWithObject:digits];
}

- (nullable NSString *)hf_phoneNormalize:(NSString *)digits {
    NSString *d = [self hf_phoneClamp:digits];
    if (![self hf_phoneLooksValid:d]) return nil;
    if ([d hasPrefix:@"0"]) {
        d = [d substringFromIndex:1];
    }
    if (d.length == 10 && [d hasPrefix:@"9"]) {
        return [@"63" stringByAppendingString:d];
    }
    return nil;
}

- (nullable NSString *)hf_validatedMobileToastIfBad {
    NSString *raw = [self hf_onlyDigits:self.hf_phoneField.text];
    if (raw.length == 0) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Please enter phone number"];
        return nil;
    }
    NSString *norm = [self hf_phoneNormalize:raw];
    if (!norm) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Please enter correct phone number"];
        return nil;
    }
    return norm;
}

#pragma mark - Checkbox / agreement

- (void)hf_tapCheck {
    self.hf_agreed = !self.hf_agreed;
    NSString *name = self.hf_agreed ? @"make_icon_sel" : @"make_icon_not";
    [self.hf_checkBtn setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    NSString *s = URL.absoluteString ?: @"";
    if ([s isEqualToString:kHFLinkPrivacy]) {
        [[HFTraceMark shared] hf_trace:HFTraceCodePrivacy];
        [self hf_openAgreement:YES];
        return NO;
    }
    if ([s isEqualToString:kHFLinkTerms]) {
        [[HFTraceMark shared] hf_trace:HFTraceCodeTerms];
        [self hf_openAgreement:NO];
        return NO;
    }
    return NO;
}

- (void)hf_openAgreement:(BOOL)privacy {
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - self.hf_lastPushAt < kHFPushDebounce) return;
    self.hf_lastPushAt = now;

    NSString *href = privacy ? [HFVaultSeal kHrefPrivacy] : [HFVaultSeal kHrefAgreement];
    NSString *title = privacy ? @"Privacy policy" : @"Service agreement";
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initWithURLString:href title:title];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:web animated:YES];
}

#pragma mark - Sign in

- (void)hf_tapEnter {
    if (self.hf_enterBusy) return;
    NSString *mobile = [self hf_validatedMobileToastIfBad];
    if (!mobile) return;
    if (!self.hf_agreed) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Please read and accept Privacy Policy and Service Agreement"];
        return;
    }

    NSString *seal = [HFQuillVault hf_quillVisageSeal] ?: @"";
    if (!seal.length) {
        [self hf_replaceOTP:mobile];
        return;
    }
    [self hf_visageGate:mobile seal:seal];
}

- (void)hf_visageGate:(NSString *)mobile seal:(NSString *)seal {
    HFVisageProbe *probe = [HFVisageLock hf_visageProbe];
    switch (probe.grant) {
        case HFVisageGrantReady: {
            self.hf_enterBusy = YES;
            self.hf_enterBtn.enabled = NO;
            [[HFTraceMark shared] hf_trace:HFTraceCodeSignIn];
            __weak typeof(self) weakSelf = self;
            [HFVisageLock hf_visageEvaluate:^(BOOL ok, BOOL denied) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                if (ok) {
                    [self hf_pwsSignIn:mobile seal:seal];
                    return;
                }
                self.hf_enterBusy = NO;
                self.hf_enterBtn.enabled = YES;
                // System Face ID "Don't Allow" / cancel / mismatch → OTP (no auto secondary sheet).
                [self hf_replaceOTP:mobile];
            }];
            break;
        }
        case HFVisageGrantDenied:
            // Already denied in Settings → secondary sheet on Sign in tap (once per launch)
            [self hf_visageDeniedThenOTP:mobile];
            break;
        case HFVisageGrantVacant:
        case HFVisageGrantOther:
        default:
            [self hf_replaceOTP:mobile];
            break;
    }
}

- (void)hf_visageDeniedThenOTP:(NSString *)mobile {
    if (sHFVisageSheetShown) {
        [self hf_replaceOTP:mobile];
        return;
    }
    sHFVisageSheetShown = YES;
    // Same style as Location / Contacts: HFCurtainBox mid-tier Cancel / Confirm
    __weak typeof(self) weakSelf = self;
    [HFPermitVeil hf_permitPresent:HFPermitKindVisage confirm:^{
        // Confirm opens Settings; stay on password page — next Sign in re-probes.
    } cancel:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self hf_replaceOTP:mobile];
    }];
}

- (void)hf_replaceOTP:(NSString *)mobile {
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - self.hf_lastPushAt < kHFPushDebounce) return;
    self.hf_lastPushAt = now;

    // Same-level replace (not push) — no back to password / Face ID page
    HFPortalGate *gate = [[HFPortalGate alloc] initWithMobile:mobile];
    UINavigationController *nav = self.navigationController;
    if (!nav) return;
    [nav setNavigationBarHidden:YES animated:NO];
    [nav setViewControllers:@[gate] animated:YES];
}

- (void)hf_pwsSignIn:(NSString *)mobile seal:(NSString *)seal {
    self.hf_enterBusy = YES;
    self.hf_enterBtn.enabled = NO;
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    NSDictionary *non = @{
        @"mobile": mobile ?: @"",
        @"password": seal ?: @""
    };
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pPwsLogin]
                              signMap:@{}
                           nonSignMap:non
                           replyClass:[HFParcelLoginReply class]
                                   ok:^(HFParcelLoginReply *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self hf_sealLogin:reply.data mobile:mobile];
    } fail:^(NSString * _Nullable msg, __unused NSString * _Nullable code) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        // Docs 51 §4.2: password login fail (wrong mobile / bad seal) — do NOT wipe Face key.
        // Keep seal so next Sign in with the correct number can still Face-login.
        self.hf_enterBusy = NO;
        self.hf_enterBtn.enabled = YES;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [[HFOrbitHint shared] hf_orbitPulse:msg.length ? msg : @"the system is busy. Please try again in 2 minutes."];
        [self hf_replaceOTP:mobile];
    }];
}

/// Same post-login chain as OTP: persist session, Face key, wipe historyMobile,
/// async registerDevice, optional new-user Face ID guide, then main.
- (void)hf_sealLogin:(HFParcelLogin *)data mobile:(NSString *)mobile {
    NSString *uid = data.userId ?: @"";
    NSString *token = data.token ?: @"";
    if (!uid.length || !token.length) {
        self.hf_enterBusy = NO;
        self.hf_enterBtn.enabled = YES;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
        return;
    }
    [HFQuillVault hf_quillPersist:uid gate:token];
    [HFQuillVault hf_quillPersistPhone:mobile];
    if (data.password.length) {
        [HFQuillVault hf_quillPutVisageSeal:data.password];
    }
    [HFQuillVault hf_quillWipeHistoryMobiles];
    [self hf_fireRegisterDeviceAsync];
    [[HFOrbitHint shared] hf_orbitHaltSpin];
    // Face ID permission only on a later Sign in, after a seal exists — not on this first success.
    self.hf_enterBusy = NO;
    self.hf_enterBtn.enabled = YES;
    [self hf_goMain];
}

- (void)hf_fireRegisterDeviceAsync {
    NSDictionary *harvest = [HFProbeAtlas hf_probeHarvest] ?: @{};
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pRegisterDevice]
                                  signMap:@{}
                               nonSignMap:harvest
                               replyClass:[HFParcelBase class]
                                       ok:^(__unused id reply) {}
                                     fail:^(__unused NSString *msg, __unused NSString *code) {}];
    });
}

- (void)hf_goMain {
    id<UISceneDelegate> del = self.view.window.windowScene.delegate;
    if ([del isKindOfClass:[SceneDelegate class]]) {
        [(SceneDelegate *)del hf_sceneShowMain];
        return;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive) continue;
        if ([scene.delegate isKindOfClass:[SceneDelegate class]]) {
            [(SceneDelegate *)scene.delegate hf_sceneShowMain];
            return;
        }
    }
}

@end
