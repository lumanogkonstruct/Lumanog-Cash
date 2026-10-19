#import "HFDriftNest.h"
#import "HFOrbitHint.h"
#import "HFProbeAtlas.h"
#import "HFQuillVault.h"
#import "HFVaultSeal.h"
#import "HFRealmGate.h"
#import "HFTraceMark.h"
#import "HFLatticeKit.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

static NSString * const kHFDriftChannel = @"iosHandler";

@interface HFDriftScriptProxy : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> target;
@end

@implementation HFDriftScriptProxy
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.target userContentController:userContentController didReceiveScriptMessage:message];
}
@end

@interface HFDriftNest () <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, copy) NSString *hf_url;
@property (nonatomic, strong) WKWebView *hf_web;
@property (nonatomic, assign) BOOL hf_injected;
@property (nonatomic, strong, nullable) dispatch_block_t hf_loadTimeout;
@property (nonatomic, strong) HFDriftScriptProxy *hf_proxy;
@end

@implementation HFDriftNest

+ (instancetype)hf_driftWithURL:(NSString *)url {
    NSString *u = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (!u.length) return nil;
    HFDriftNest *vc = [[HFDriftNest alloc] initWithNibName:nil bundle:nil];
    vc.hf_url = u;
    vc.hf_navTitle = @"Accurate Recommendation";
    return vc;
}

- (void)dealloc {
    [self hf_driftCancelTimeout];
    [self.hf_web.configuration.userContentController removeScriptMessageHandlerForName:kHFDriftChannel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor hf_prismHex:@"#F5EDE2"];

    WKUserContentController *ucc = [WKUserContentController new];
    self.hf_proxy = [HFDriftScriptProxy new];
    self.hf_proxy.target = self;
    [ucc addScriptMessageHandler:self.hf_proxy name:kHFDriftChannel];

    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    cfg.userContentController = ucc;
    cfg.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        cfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }

    self.hf_web = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.hf_web.navigationDelegate = self;
    self.hf_web.customUserAgent = [HFProbeAtlas hf_probeUA];
    self.hf_web.allowsBackForwardNavigationGestures = YES;
    self.hf_web.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    [self.view addSubview:self.hf_web];
    [self.hf_web mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    dispatch_block_t work = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.hf_loadTimeout = nil;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
    });
    self.hf_loadTimeout = work;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), work);

    NSURL *url = [NSURL URLWithString:self.hf_url];
    if (!url && ![self.hf_url hasPrefix:@"http"]) {
        url = [NSURL URLWithString:[@"https://" stringByAppendingString:self.hf_url]];
    }
    if (url) {
        [self.hf_web loadRequest:[NSURLRequest requestWithURL:url]];
    } else {
        [self hf_driftCancelTimeout];
        [[HFOrbitHint shared] hf_orbitHaltSpin];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    // docs_phl/49 §5.1 — swipe-back allowed (override canvas default).
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self hf_driftCancelTimeout];
    [[HFOrbitHint shared] hf_orbitHaltSpin];
}

- (void)hf_driftCancelTimeout {
    if (self.hf_loadTimeout) {
        dispatch_block_cancel(self.hf_loadTimeout);
        self.hf_loadTimeout = nil;
    }
}

#pragma mark - Inject rejectData

- (void)hf_driftInjectOnce {
    if (self.hf_injected) return;
    self.hf_injected = YES;

    NSDictionary *payload = @{
        @"appId": [HFVaultSeal kAlphaSeed] ?: @"",
        @"salt": [HFVaultSeal kBetaGrain] ?: @"",
        @"mobile": [HFQuillVault hf_quillPhone] ?: @"",
        @"baseUrl": [[HFRealmGate shared] hf_realmCurrent] ?: @"",
        @"userId": [HFQuillVault hf_quillUid] ?: @"",
        @"token": [HFQuillVault hf_quillGate] ?: @""
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *json = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{}";
    NSString *escaped = [[[json stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
                          stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
                         stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    NSString *js = [NSString stringWithFormat:@"typeof rejectData==='function'&&rejectData('%@');", escaped];
    [self.hf_web evaluateJavaScript:js completionHandler:nil];
    // eventCode 500 is reported by H5 after receiving rejectData — not by native.
}

#pragma mark - thirdUrl

- (void)hf_driftOpenThird:(NSString *)raw {
    NSString *body = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (![body hasPrefix:@"thirdUrl"]) return;
    NSString *parsed = [[body stringByReplacingOccurrencesOfString:@"thirdUrl=" withString:@""]
                        stringByReplacingOccurrencesOfString:@"type=" withString:@""];
    NSArray *parts = [parsed componentsSeparatedByString:@"&"];
    NSString *urlString = parts.firstObject
        ? [parts.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    if (!urlString.length) return;
    NSString *remark = parts.count > 1
        ? [parts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"NULL";
    if (!remark.length) remark = @"NULL";
    // docs_phl/49 §6 — native only reports 502 (remark1 = type).
    [[HFTraceMark shared] hf_trace:HFTraceCodeRejectOpen content:nil r1:remark r2:nil r3:nil];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    // Open fail: silent (no Toast).
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self hf_driftCancelTimeout];
    [[HFOrbitHint shared] hf_orbitHaltSpin];
    [self hf_driftInjectOnce];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)error;
    [self hf_driftCancelTimeout];
    [[HFOrbitHint shared] hf_orbitHaltSpin];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)error;
    [self hf_driftCancelTimeout];
    [[HFOrbitHint shared] hf_orbitHaltSpin];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *s = navigationAction.request.URL.absoluteString ?: @"";
    if ([s hasPrefix:@"http"] || [s hasPrefix:@"about:blank"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    decisionHandler(WKNavigationActionPolicyCancel);
    NSURL *url = navigationAction.request.URL;
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:kHFDriftChannel]) return;
    if (![message.body isKindOfClass:[NSString class]]) return;
    NSString *body = (NSString *)message.body;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hf_driftOpenThird:body];
    });
}

@end
