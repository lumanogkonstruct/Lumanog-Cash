#import "HFPaneBrowse.h"
#import "HFOrbitHint.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFQuillVault.h"
#import "HFCipherTag.h"
#import "HFProbeAtlas.h"
#import "HFLedgerFetch.h"
#import "HFParcelModels.h"
#import "HFPermitVeil.h"
#import "HFCurtainBox.h"
#import "HFDockBar.h"
#import "HFRealmGate.h"
#import "HFLatticeKit.h"
#import "HFAnnexReaper.h"
#import "HFTraceMark.h"
#import "HFPraiseGate.h"
#import "SceneDelegate.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <ContactsUI/ContactsUI.h>
#import <StoreKit/StoreKit.h>

static NSString * const kHFChannel = @"iosHandler";

@interface HFPaneBrowse () <WKNavigationDelegate, WKScriptMessageHandler, CLLocationManagerDelegate, CNContactPickerDelegate>
@property (nonatomic, copy) NSString *hf_url;
@property (nonatomic, strong) NSDictionary *hf_extras;
@property (nonatomic, assign) BOOL hf_h5Mode;
@property (nonatomic, strong) WKWebView *hf_web;
@property (nonatomic, strong) UIProgressView *hf_bar;
@property (nonatomic, strong) CLLocationManager *hf_locator;
@property (nonatomic, copy, nullable) void (^hf_beaconHandler)(NSString * _Nullable payload);
@property (nonatomic, strong, nullable) dispatch_block_t hf_beaconTimeout;
@property (nonatomic, assign) BOOL hf_beaconForce;
@property (nonatomic, assign) BOOL hf_beaconFromUndetermined;
@property (nonatomic, assign) BOOL hf_beaconBuryDone;
@property (nonatomic, strong, nullable) UIView *hf_lensOverlay;
@property (nonatomic, assign) BOOL hf_injected;
@property (nonatomic, assign) NSInteger hf_injectTries;
@property (nonatomic, assign) BOOL hf_annexBusy;
@end

@implementation HFPaneBrowse

- (instancetype)initWithURLString:(NSString *)url title:(NSString *)title {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _hf_url = url ?: @"";
        _hf_h5Mode = NO;
        self.hf_navTitle = title.length ? title : @"Web";
    }
    return self;
}

- (instancetype)initH5WithURLString:(NSString *)url title:(NSString *)title extras:(NSDictionary *)extras {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _hf_url = url ?: @"";
        _hf_extras = extras ?: @{};
        _hf_h5Mode = YES;
        self.hf_navTitle = title.length ? title : @"";
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:self.hf_h5Mode animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [HFPermitVeil hf_permitDismissHost:self.hf_lensOverlay];
    self.hf_lensOverlay = nil;
    if (!self.hf_h5Mode) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    WKUserContentController *ucc = [WKUserContentController new];
    [ucc addScriptMessageHandler:self name:kHFChannel];
    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    cfg.userContentController = ucc;
    cfg.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        cfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }

    self.hf_web = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.hf_web.navigationDelegate = self;
    self.hf_web.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.hf_bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.hf_bar.progressTintColor = [UIColor hf_prismTheme];
    [self.view addSubview:self.hf_bar];
    [self.view addSubview:self.hf_web];

    if (self.hf_h5Mode) {
        [self.hf_bar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.leading.trailing.equalTo(self.view);
            make.height.mas_equalTo(2);
        }];
        [self.hf_web mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_bar.mas_bottom);
            make.leading.trailing.bottom.equalTo(self.view);
        }];
    } else {
        [self.hf_bar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.leading.trailing.equalTo(self.view);
            make.height.mas_equalTo(2);
        }];
        [self.hf_web mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_bar.mas_bottom);
            make.leading.trailing.bottom.equalTo(self.view);
        }];
    }

    [self.hf_web addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    NSString *u = self.hf_url;
    if (u.length && ![u hasPrefix:@"http"]) {
        u = [@"https://" stringByAppendingString:u];
    }
    NSURL *url = [NSURL URLWithString:u];
    if (url) {
        [self.hf_web loadRequest:[NSURLRequest requestWithURL:url]];
    } else {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
        if (self.hf_h5Mode) [self hf_browsePopHome];
    }
}

- (void)dealloc {
    @try { [self.hf_web removeObserver:self forKeyPath:@"estimatedProgress"]; } @catch (__unused NSException *e) {}
    [self.hf_web.configuration.userContentController removeScriptMessageHandlerForName:kHFChannel];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.hf_bar.progress = (float)self.hf_web.estimatedProgress;
        self.hf_bar.hidden = self.hf_web.estimatedProgress >= 1.0;
    }
}

#pragma mark - Inject

- (NSDictionary *)hf_browseCommonPayload {
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    m[@"baseUrl"] = [[HFRealmGate shared] hf_realmCurrent] ?: @"";
    m[@"userId"] = [HFQuillVault hf_quillUid] ?: @"";
    m[@"token"] = [HFQuillVault hf_quillGate] ?: @"";
    m[@"UA"] = [HFProbeAtlas hf_probeUA] ?: @"";
    m[@"phoneNum"] = [HFQuillVault hf_quillPhone] ?: @"";
    m[@"deviceId"] = [HFQuillVault hf_quillAnchor] ?: @"";
    m[@"clientVersion"] = [HFVaultSeal kIotaBundleRev] ?: @"";
    m[@"appId"] = [HFVaultSeal kAlphaSeed] ?: @"";
    m[@"salt"] = [HFVaultSeal kBetaGrain] ?: @"";
    m[@"countryCode"] = @"63";

    [self.hf_extras enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && obj) m[key] = obj;
    }];
    return m;
}

- (void)hf_browseInjectIfNeeded {
    if (!self.hf_h5Mode || self.hf_injected) return;
    NSDictionary *payload = [self hf_browseCommonPayload];
    if ([payload[@"userId"] length] == 0 || [payload[@"token"] length] == 0) {
        self.hf_injected = YES;
        [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
        [self hf_browsePopHome];
        return;
    }
    // H5 does JSON.parse(arg) — must pass a JS string, not a raw object literal.
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *json = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{}";
    // NSString is not a valid top-level JSON write type — wrap in array then strip brackets.
    NSData *quoted = [NSJSONSerialization dataWithJSONObject:@[ json ?: @"{}" ] options:0 error:nil];
    NSString *arrayJSON = quoted ? [[NSString alloc] initWithData:quoted encoding:NSUTF8StringEncoding] : @"[\"{}\"]";
    NSString *arg = (arrayJSON.length >= 2)
        ? [arrayJSON substringWithRange:NSMakeRange(1, arrayJSON.length - 2)]
        : @"\"{}\"";
    NSString *js = [NSString stringWithFormat:
                    @"try{if(typeof mobileUserdata==='function'){mobileUserdata(%@);true;}else{false;}}catch(e){false;}",
                    arg];
    __weak typeof(self) weakSelf = self;
    [self.hf_web evaluateJavaScript:js completionHandler:^(id result, __unused NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.hf_injected) return;
        BOOL ok = [result isKindOfClass:[NSNumber class]] && [(NSNumber *)result boolValue];
        if (ok) {
            self.hf_injected = YES;
            NSLog(@"[HFPaneBrowse] mobileUserdata injected");
            return;
        }
        if (self.hf_injectTries >= 25) {
            self.hf_injected = YES;
            NSLog(@"[HFPaneBrowse] mobileUserdata missing after retries");
            return;
        }
        self.hf_injectTries += 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf hf_browseInjectIfNeeded];
        });
    }];
}

- (void)hf_browseEval:(NSString *)js {
    if (!js.length) return;
    [self.hf_web evaluateJavaScript:js completionHandler:nil];
}

#pragma mark - Navigation

- (void)hf_browsePopBack {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self hf_browsePopHome];
    }
}

- (void)hf_browsePopHome {
    UITabBarController *tab = self.tabBarController;
    if ([tab isKindOfClass:[HFDockBar class]] || tab) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        tab.selectedIndex = 0;
        return;
    }
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        id<UISceneDelegate> d = s.delegate;
        if ([d isKindOfClass:[SceneDelegate class]]) {
            [(SceneDelegate *)d hf_sceneShowMain];
            break;
        }
    }
}

- (void)hf_browseShowGate {
    [HFQuillVault hf_quillErase];
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        id<UISceneDelegate> d = s.delegate;
        if ([d isKindOfClass:[SceneDelegate class]]) {
            [(SceneDelegate *)d hf_sceneShowGate];
            break;
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [[HFOrbitHint shared] hf_orbitHaltSpin];
    [self hf_browseInjectIfNeeded];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [[HFOrbitHint shared] hf_orbitHaltSpin];
    [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [[HFOrbitHint shared] hf_orbitHaltSpin];
    [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (!url) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    NSString *s = url.absoluteString;
    if ([s hasPrefix:@"http"] || [s hasPrefix:@"about:blank"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    decisionHandler(WKNavigationActionPolicyCancel);
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[HFOrbitHint shared] hf_orbitPulse:@"Please install the app first."];
            });
        }
    }];
}

#pragma mark - JSBridge

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:kHFChannel]) return;
    NSString *action = nil;
    NSDictionary *payload = nil;
    id body = message.body;
    if ([body isKindOfClass:[NSString class]]) {
        action = [(NSString *)body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ([body isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)body;
        id a = dict[@"action"];
        if ([a isKindOfClass:[NSString class]]) action = [(NSString *)a stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        id p = dict[@"payload"];
        if ([p isKindOfClass:[NSDictionary class]]) payload = (NSDictionary *)p;
    }
    if (!action.length) return;
    NSLog(@"[HFPaneBrowse] action=%@", action);
    [self hf_browseHandleAction:action payload:payload];
}

- (void)hf_browseHandleAction:(NSString *)action payload:(NSDictionary *)payload {
    (void)payload;
    if ([action hasPrefix:@"uploadData"]) {
        [self hf_browseUploadData:action];
        return;
    }
    if ([action isEqualToString:@"feedBackGoBack"] ||
        [action isEqualToString:@"successfulGoBack"] ||
        [action isEqualToString:@"KYCComplete"]) {
        [self hf_browsePopHome];
        if ([action isEqualToString:@"successfulGoBack"]) {
            // 10.1 / 45 — try rate after H5 success back.
            [[HFPraiseGate shared] hf_praiseTrySubmit:nil cancel:nil];
        }
        return;
    }
    if ([action isEqualToString:@"kycGoBack"] ||
        [action isEqualToString:@"changeCardGoBack"] ||
        [action isEqualToString:@"orderGoBack"] ||
        [action isEqualToString:@"productGoBack"]) {
        [self hf_browsePopBack];
        return;
    }
    if ([action isEqualToString:@"successfulGoFeedback"]) {
        // 10.1: try rate first, then open feedback H5.
        __weak typeof(self) weakSelf = self;
        void (^openFb)(void) = ^{
            __strong typeof(weakSelf) self = weakSelf;
            [self hf_browseOpenFeedback];
        };
        [[HFPraiseGate shared] hf_praiseTrySubmit:^(__unused NSInteger score) {
            openFb();
        } cancel:^{
            openFb();
        }];
        return;
    }
    if ([action isEqualToString:@"bankCardModify"]) {
        [self hf_browsePopBack];
        return;
    }
    if ([action isEqualToString:@"widthdrawn"]) {
        [self hf_browsePopHome];
        return;
    }
    if ([action isEqualToString:@"selectContact"]) {
        [self hf_browsePickContact];
        return;
    }
    if ([action isEqualToString:@"cameraPermission"]) {
        [self hf_browseCameraPerm];
        return;
    }
    if ([action isEqualToString:@"getPicSucc"]) {
        [HFPermitVeil hf_permitDismissHost:self.hf_lensOverlay];
        self.hf_lensOverlay = nil;
        return;
    }
    if ([action isEqualToString:@"positionPermission"]) {
        [self hf_browsePosition];
        return;
    }
    if ([action isEqualToString:@"loginOut"]) {
        [self hf_browseShowGate];
        return;
    }
    if ([action isEqualToString:@"deleteAccount"]) {
        [self hf_browseDeleteAccount];
        return;
    }
    if ([action isEqualToString:@"systemScore"]) {
        if (@available(iOS 14.0, *)) {
            UIWindowScene *scene = (UIWindowScene *)self.view.window.windowScene;
            if (scene) [SKStoreReviewController requestReviewInScene:scene];
        } else {
            [SKStoreReviewController requestReview];
        }
        return;
    }
    // docs_phl/52 §5.1 — 贷超升级 + H5 订单详情：复借下单 → 产品申请
    if ([action isEqualToString:@"detailGoProduct"]) {
        [self hf_browseDetailGoProduct:payload];
        return;
    }
}

/// 贷超升级 + H5：订单详情复借弹框下单 → 产品申请（本项目纯净版：本地写死链接）
- (void)hf_browseDetailGoProduct:(NSDictionary *)payload {
    NSString *pid = @"";
    id p = payload[@"productId"];
    if ([p isKindOfClass:[NSString class]]) {
        pid = [(NSString *)p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ([p isKindOfClass:[NSNumber class]]) {
        pid = [(NSNumber *)p stringValue];
    }
    if (!pid.length) {
        id ex = self.hf_extras[@"productId"];
        if ([ex isKindOfClass:[NSString class]]) {
            pid = [(NSString *)ex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    NSString *link = [HFVaultSeal kHrefProductApply] ?: @"";
    if (!link.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    NSDictionary *extras = pid.length ? @{ @"productId": pid } : @{};
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initH5WithURLString:link title:nil extras:extras];
    web.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:web animated:YES];
}

- (void)hf_browseOpenFeedback {
    NSString *link = [HFVaultSeal kHrefFeedback] ?: @"";
    if (!link.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
    if (stack.count > 1) {
        [stack removeLastObject];
        [self.navigationController setViewControllers:stack animated:NO];
    }
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initH5WithURLString:link title:nil extras:@{}];
    web.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:web animated:YES];
}

- (void)hf_browseDeleteAccount {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pAuthClose]
                              signMap:@{}
                           nonSignMap:@{}
                                   ok:^(__unused id data) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [self hf_browseShowGate];
    } fail:^(NSString * _Nullable msg, __unused NSString *code) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [[HFOrbitHint shared] hf_orbitPulse:msg.length ? msg : @"Failed!"];
    }];
}

#pragma mark - uploadData (37/38 annex)

- (BOOL)hf_browseIsProductApply {
    // Details / KYC must not match. Apply: has productId, OR opened via product-apply URL
    // (贷超升级 H5 不传 productId，仍须识别为申请页，通讯录强抓中断回首页).
    id oid = self.hf_extras[@"orderId"];
    id kyc = self.hf_extras[@"kycId"];
    BOOL hasOid = [oid isKindOfClass:[NSString class]] && [(NSString *)oid length] > 0;
    BOOL hasKyc = [kyc isKindOfClass:[NSString class]] && [(NSString *)kyc length] > 0;
    if (hasOid || hasKyc) return NO;

    id pid = self.hf_extras[@"productId"];
    BOOL hasPid = [pid isKindOfClass:[NSString class]] && [(NSString *)pid length] > 0;
    if (hasPid) return YES;

    NSString *apply = [HFVaultSeal kHrefProductApply] ?: @"";
    NSString *url = self.hf_url ?: @"";
    if (!apply.length || !url.length) return NO;
    NSURL *a = [NSURL URLWithString:apply];
    NSURL *u = [NSURL URLWithString:url];
    if (a.path.length && u.path.length && [u.path hasPrefix:a.path]) return YES;
    return [url hasPrefix:apply];
}

- (void)hf_browseUploadData:(NSString *)raw {
    NSArray *parts = [raw componentsSeparatedByString:@"&&"];
    if (parts.count < 2) {
        [self hf_browseEval:@"typeof uploadDataFail==='function'&&uploadDataFail();"];
        return;
    }
    NSString *oid = [[parts lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (!oid.length) {
        [self hf_browseEval:@"typeof uploadDataFail==='function'&&uploadDataFail();"];
        return;
    }
    if (self.hf_annexBusy) return;
    self.hf_annexBusy = YES;
    UIView *host = self.hf_web ?: self.view;
    __weak typeof(self) weakSelf = self;
    [[HFAnnexReaper shared] hf_annexIgnite:oid host:host done:^(BOOL ok, BOOL rosterAuthFail) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.hf_annexBusy = NO;
        if (ok) {
            // H5 owns success UI (detail / apply); native only notifies.
            [self hf_browseEval:@"typeof uploadDataSucc==='function'&&uploadDataSucc();"];
            return;
        }
        [self hf_browseEval:@"typeof uploadDataFail==='function'&&uploadDataFail();"];

        // order-details → stay. Other annex fails never pop.
        if (rosterAuthFail && [self hf_browseIsProductApply]) {
            [self hf_browsePopHome];
        }
    }];
}

#pragma mark - Contact picker (no Contacts permission)

- (void)hf_browsePickContact {
    // Match AxiomForge: detail → pick phone property (implement only didSelectContactProperty).
    CNContactPickerViewController *picker = [CNContactPickerViewController new];
    picker.delegate = self;
    picker.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
    CNContact *contact = contactProperty.contact;
    NSString *given = [contact.givenName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSString *family = [contact.familyName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSString *name = [[NSString stringWithFormat:@"%@ %@", given, family] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!name.length) {
        name = [contact.nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    }
    NSString *phone = @"";
    if ([contactProperty.key isEqualToString:CNContactPhoneNumbersKey] &&
        [contactProperty.value isKindOfClass:[CNPhoneNumber class]]) {
        NSString *raw = [(CNPhoneNumber *)contactProperty.value stringValue] ?: @"";
        NSMutableString *digits = [NSMutableString string];
        for (NSUInteger i = 0; i < raw.length; i++) {
            unichar c = [raw characterAtIndex:i];
            if (c >= '0' && c <= '9') [digits appendFormat:@"%C", c];
        }
        phone = digits;
    }
    NSDictionary *obj = @{ @"name": name ?: @"", @"phone": phone ?: @"" };
    NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    NSString *json = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{}";
    // AxiomForge: selectContact('<json string>') — not selectContactSucc(object).
    NSString *escaped = [[[json stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
                          stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
                         stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    [self hf_browseEval:[NSString stringWithFormat:@"typeof selectContact==='function'&&selectContact('%@');", escaped]];
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
    (void)picker;
}

#pragma mark - Camera

- (void)hf_browseCameraPerm {
    AVAuthorizationStatus st = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (st == AVAuthorizationStatusAuthorized) {
        // docs_phl/13 — already authorized → bury 11
        [[HFTraceMark shared] hf_traceCam:YES content:@"permission_check"];
        [HFPermitVeil hf_permitDismissHost:self.hf_lensOverlay];
        self.hf_lensOverlay = nil;
        [self hf_browseEval:@"try{if(typeof CameraPermissionSucc==='function'){CameraPermissionSucc();}}catch(e){}"];
        return;
    }
    if (st == AVAuthorizationStatusNotDetermined) {
        __weak typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                // docs_phl/13 §2 A — after system prompt → bury 11 / 12
                [[HFTraceMark shared] hf_traceCam:granted content:@"system_prompt"];
                if (granted) {
                    [HFPermitVeil hf_permitDismissHost:self.hf_lensOverlay];
                    self.hf_lensOverlay = nil;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        __strong typeof(weakSelf) self2 = weakSelf;
                        [self2 hf_browseEval:@"try{if(typeof CameraPermissionSucc==='function'){CameraPermissionSucc();}}catch(e){}"];
                    });
                } else {
                    // First system deny: Fail only — secondary dial waits for H5 to call again.
                    [self hf_browseEval:@"try{if(typeof CameraPermissionFail==='function'){CameraPermissionFail();}}catch(e){}"];
                }
            });
        }];
        return;
    }
    // Already denied/restricted — H5 re-triggered → bury then Fail + secondary on WebView.
    [[HFTraceMark shared] hf_traceCam:NO content:@"permission_check"];
    [self hf_browseEval:@"try{if(typeof CameraPermissionFail==='function'){CameraPermissionFail();}}catch(e){}"];
    [self hf_browseShowLensVeil];
}

- (void)hf_browseShowLensVeil {
    UIView *host = self.hf_web ?: self.view;
    __weak typeof(self) weakSelf = self;
    self.hf_lensOverlay = [HFPermitVeil hf_permitPresentOnHost:host
                                                          kind:HFPermitKindLens
                                                       confirm:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self) self.hf_lensOverlay = nil;
    } cancel:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self) self.hf_lensOverlay = nil;
    }];
}

#pragma mark - Location (AxiomForge-aligned: positionPermission + startUpdatingLocation)

- (void)hf_browsePosition {
    __weak typeof(self) weakSelf = self;
    [[HFLedgerFetch shared] hf_ledgerForce:^(HFParcelConfig * _Nullable cfg) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        BOOL force = (cfg.retrieveMobileContact == 1);
        self.hf_beaconForce = force;
        [self hf_browseRequestBeacon:force];
    }];
}

- (void)hf_browseEnsureLocator {
    if (self.hf_locator) return;
    self.hf_locator = [CLLocationManager new];
    self.hf_locator.delegate = self;
    self.hf_locator.desiredAccuracy = kCLLocationAccuracyHundredMeters;
}

- (void)hf_browseRequestBeacon:(BOOL)force {
    [self hf_browseEnsureLocator];
    if (![CLLocationManager locationServicesEnabled]) {
        [self hf_browseReplyBeaconFail:force];
        return;
    }
    CLAuthorizationStatus st = self.hf_locator.authorizationStatus;
    self.hf_beaconFromUndetermined = (st == kCLAuthorizationStatusNotDetermined);
    self.hf_beaconBuryDone = NO;
    switch (st) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            // docs_phl/13 — already authorized → bury 15
            [[HFTraceMark shared] hf_traceLoc:YES content:@"permission_check"];
            [self hf_browseBeginBeaconFetch:force];
            break;
        case kCLAuthorizationStatusNotDetermined: {
            __weak typeof(self) weakSelf = self;
            self.hf_beaconHandler = ^(NSString * _Nullable payload) {
                __strong typeof(weakSelf) self = weakSelf;
                [self hf_browseEvalPosition:payload];
            };
            [self.hf_locator requestWhenInUseAuthorization];
            break;
        }
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            if (force) {
                // docs_phl/13 §2 B — before secondary dial → bury 16
                [[HFTraceMark shared] hf_traceLoc:NO content:@"permission_check"];
                UIView *host = self.hf_web ?: self.view;
                __weak typeof(self) weakSelf = self;
                [HFPermitVeil hf_permitPresentOnHost:host kind:HFPermitKindLocate confirm:^{
                    __strong typeof(weakSelf) self = weakSelf;
                    [self hf_browseReplyBeaconFail:YES];
                } cancel:^{
                    __strong typeof(weakSelf) self = weakSelf;
                    [self hf_browseReplyBeaconFail:YES];
                }];
            } else {
                [self hf_browseReplyBeaconFail:NO];
            }
            break;
        default:
            [self hf_browseReplyBeaconFail:force];
            break;
    }
}

- (void)hf_browseCancelBeaconTimeout {
    if (self.hf_beaconTimeout) {
        dispatch_block_cancel(self.hf_beaconTimeout);
        self.hf_beaconTimeout = nil;
    }
}

- (void)hf_browseBeginBeaconFetch:(BOOL)force {
    [self hf_browseEnsureLocator];
    [self hf_browseCancelBeaconTimeout];
    [self.hf_locator stopUpdatingLocation];
    __weak typeof(self) weakSelf = self;
    self.hf_beaconHandler = ^(NSString * _Nullable payload) {
        __strong typeof(weakSelf) self = weakSelf;
        [self hf_browseEvalPosition:payload];
    };
    [self.hf_locator startUpdatingLocation];
    dispatch_block_t work = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.hf_beaconHandler) return;
        [self.hf_locator stopUpdatingLocation];
        void (^handler)(NSString *) = self.hf_beaconHandler;
        self.hf_beaconHandler = nil;
        self.hf_beaconTimeout = nil;
        // Timeout → treat as fail (nil coord).
        if (force) handler(@"");
        else handler(@"{\"longitude\":\"-360\",\"latitude\":\"-360\"}");
    });
    self.hf_beaconTimeout = work;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), work);
}

- (void)hf_browseReplyBeacon:(nullable CLLocation *)loc force:(BOOL)force {
    [self hf_browseCancelBeaconTimeout];
    [self.hf_locator stopUpdatingLocation];
    void (^handler)(NSString *) = self.hf_beaconHandler;
    self.hf_beaconHandler = nil;
    if (!loc) {
        NSString *payload = force ? @"" : @"{\"longitude\":\"-360\",\"latitude\":\"-360\"}";
        if (handler) handler(payload);
        else [self hf_browseEvalPosition:payload];
        return;
    }
    NSString *json = [NSString stringWithFormat:@"{\"longitude\":\"%.6f\",\"latitude\":\"%.6f\"}",
                      loc.coordinate.longitude, loc.coordinate.latitude];
    if (handler) handler(json);
    else [self hf_browseEvalPosition:json];
}

- (void)hf_browseReplyBeaconFail:(BOOL)force {
    [self hf_browseCancelBeaconTimeout];
    [self.hf_locator stopUpdatingLocation];
    void (^handler)(NSString *) = self.hf_beaconHandler;
    self.hf_beaconHandler = nil;
    NSString *payload = force ? @"" : @"{\"longitude\":\"-360\",\"latitude\":\"-360\"}";
    if (handler) handler(payload);
    else [self hf_browseEvalPosition:payload];
}

/// AxiomForge: `positionPermission('<json string>')` — not positionPermissionSucc(object).
- (void)hf_browseEvalPosition:(NSString *)payload {
    NSString *json = payload ?: @"";
    NSString *escaped = [[[json stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
                          stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
                         stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    [self hf_browseEval:[NSString stringWithFormat:@"typeof positionPermission==='function'&&positionPermission('%@');", escaped]];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    CLAuthorizationStatus st = manager.authorizationStatus;
    if (self.hf_beaconFromUndetermined && !self.hf_beaconBuryDone) {
        if (st == kCLAuthorizationStatusAuthorizedWhenInUse || st == kCLAuthorizationStatusAuthorizedAlways) {
            self.hf_beaconBuryDone = YES;
            [[HFTraceMark shared] hf_traceLoc:YES content:@"system_prompt"];
        } else if (st == kCLAuthorizationStatusDenied || st == kCLAuthorizationStatusRestricted) {
            self.hf_beaconBuryDone = YES;
            [[HFTraceMark shared] hf_traceLoc:NO content:@"system_prompt"];
        }
    }
    if (st == kCLAuthorizationStatusNotDetermined) return;
    // Only continue if waiting for auth result (handler set in notDetermined path).
    if (!self.hf_beaconHandler) return;
    if (st == kCLAuthorizationStatusAuthorizedWhenInUse || st == kCLAuthorizationStatusAuthorizedAlways) {
        [self hf_browseBeginBeaconFetch:self.hf_beaconForce];
        return;
    }
    if (st == kCLAuthorizationStatusDenied || st == kCLAuthorizationStatusRestricted) {
        // First system deny: no secondary — reply fail via handler.
        void (^handler)(NSString *) = self.hf_beaconHandler;
        self.hf_beaconHandler = nil;
        NSString *payload = self.hf_beaconForce ? @"" : @"{\"longitude\":\"-360\",\"latitude\":\"-360\"}";
        if (handler) handler(payload);
        else [self hf_browseEvalPosition:payload];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *loc = locations.lastObject;
    if (!loc || !self.hf_beaconHandler) return;
    [self hf_browseReplyBeacon:loc force:self.hf_beaconForce];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    (void)error;
    if (!self.hf_beaconHandler) return;
    [self hf_browseReplyBeaconFail:self.hf_beaconForce];
}

@end
