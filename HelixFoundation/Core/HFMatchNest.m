#import "HFMatchNest.h"
#import "HFLatticeKit.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFParcelModels.h"
#import "HFPaneBrowse.h"
#import "HFDriftNest.h"
#import "HFLedgerFetch.h"
#import "HFDockBar.h"
#import "HFOrbitHint.h"
#import <Masonry/Masonry.h>
#import <YYModel/YYModel.h>

static NSString * const kHFMatchEmptyCopy =
    @"You do not currently meet the requirements for this product. Once a more suitable loan product becomes available, we will notify you through the app. Please stay tuned.";

static NSString * const kHFMatchPopupBody =
    @"Congratulations on completing your order! Apply for a new loan now, enjoy exclusive offers, and realize your dream easily!";

static const NSTimeInterval kHFMatchMinShow = 1.2;

@interface HFMatchNest ()
@property (nonatomic, strong) UILabel *hf_copyLab;
@property (nonatomic, strong) UIButton *hf_viewNowBtn;
@property (nonatomic, strong) UIImageView *hf_iconIV;
@property (nonatomic, strong, nullable) UIWindow *hf_matchWin;
@property (nonatomic, assign) BOOL hf_busy;
@property (nonatomic, assign) BOOL hf_allowBack;
@property (nonatomic, strong, nullable) dispatch_block_t hf_timeout;
@property (nonatomic, assign) CFAbsoluteTime hf_matchShownAt;
@property (nonatomic, copy, nullable) void (^hf_pendingFinish)(void);
@end

@implementation HFMatchNest

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"Accurate Recommendation";
    self.title = self.hf_navTitle;
    self.hf_canvasTint = [UIColor hf_prismHex:@"#F5EDE2"];
    [self hf_applyCanvas];
    self.hf_allowBack = NO;
    __weak typeof(self) weakSelf = self;
    self.hf_onBackGate = ^BOOL {
        return weakSelf.hf_allowBack;
    };
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    [self hf_matchBuildPage];
    [self hf_matchFire];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)dealloc {
    [self hf_matchCancelTimeout];
    [self hf_matchTearWin];
}

- (void)hf_matchBuildPage {
    UIColor *ink = [UIColor hf_prismInk];

    self.hf_copyLab = [UILabel new];
    self.hf_copyLab.textColor = ink;
    self.hf_copyLab.font = [UIFont hf_latticeGlyph:15 mass:UIFontWeightRegular];
    self.hf_copyLab.numberOfLines = 0;
    self.hf_copyLab.hidden = YES;
    [self.view addSubview:self.hf_copyLab];

    self.hf_viewNowBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.hf_viewNowBtn setTitle:@"View Now >>" forState:UIControlStateNormal];
    [self.hf_viewNowBtn setTitleColor:[UIColor hf_prismTheme] forState:UIControlStateNormal];
    self.hf_viewNowBtn.titleLabel.font = [UIFont hf_latticeGlyph:15 mass:UIFontWeightRegular];
    self.hf_viewNowBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.hf_viewNowBtn addTarget:self action:@selector(hf_matchTapViewNow) forControlEvents:UIControlEventTouchUpInside];
    self.hf_viewNowBtn.hidden = YES;
    [self.view addSubview:self.hf_viewNowBtn];

    self.hf_iconIV = [UIImageView new];
    self.hf_iconIV.contentMode = UIViewContentModeScaleAspectFit;
    self.hf_iconIV.hidden = YES;
    [self.view addSubview:self.hf_iconIV];

    [self.hf_copyLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(24);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];
    [self.hf_viewNowBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_copyLab.mas_bottom).offset(12);
        make.leading.equalTo(self.hf_copyLab);
        make.height.mas_equalTo(28);
    }];
    [self.hf_iconIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-20);
        make.width.height.mas_equalTo(72);
    }];
}

#pragma mark - Matching popup

- (void)hf_matchShowWin {
    [[HFOrbitHint shared] hf_orbitForceHaltSpin];
    if (self.hf_matchWin && !self.hf_matchWin.hidden) return;

    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if (!scene) {
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
    }
    if (!scene) return;

    UIWindow *w = [[UIWindow alloc] initWithWindowScene:scene];
    w.windowLevel = UIWindowLevelAlert - 1;
    w.backgroundColor = UIColor.clearColor;

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.clearColor;

    UIView *dim = [UIView new];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    [vc.view addSubview:dim];
    dim.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [dim.topAnchor constraintEqualToAnchor:vc.view.topAnchor],
        [dim.bottomAnchor constraintEqualToAnchor:vc.view.bottomAnchor],
        [dim.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor],
        [dim.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor],
    ]];

    UIView *card = [UIView new];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 16;
    card.clipsToBounds = YES;
    [dim addSubview:card];
    card.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *title = [UILabel new];
    title.text = @"Matching in progress";
    title.textColor = [UIColor hf_prismInk];
    title.font = [UIFont hf_latticeGlyph:17 mass:UIFontWeightMedium];
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];

    UIImageView *clock = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dssl_ppz"]];
    clock.contentMode = UIViewContentModeScaleAspectFit;
    [card addSubview:clock];

    UILabel *body = [UILabel new];
    body.text = kHFMatchPopupBody;
    body.textColor = [UIColor hf_prismInk];
    body.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    body.numberOfLines = 0;
    body.textAlignment = NSTextAlignmentCenter;
    [card addSubview:body];

    title.translatesAutoresizingMaskIntoConstraints = NO;
    clock.translatesAutoresizingMaskIntoConstraints = NO;
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:dim.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:dim.centerYAnchor],
        [card.leadingAnchor constraintEqualToAnchor:dim.leadingAnchor constant:36],
        [card.trailingAnchor constraintEqualToAnchor:dim.trailingAnchor constant:-36],

        [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],
        [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],

        [clock.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:18],
        [clock.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [clock.widthAnchor constraintEqualToConstant:48],
        [clock.heightAnchor constraintEqualToConstant:48],

        [body.topAnchor constraintEqualToAnchor:clock.bottomAnchor constant:16],
        [body.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [body.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [body.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22],
    ]];

    w.rootViewController = vc;
    w.hidden = NO;
    [w makeKeyAndVisible];
    self.hf_matchWin = w;
    self.hf_matchShownAt = CFAbsoluteTimeGetCurrent();
}

- (void)hf_matchTearWin {
    if (!self.hf_matchWin) return;
    UIWindow *dying = self.hf_matchWin;
    self.hf_matchWin = nil;
    dying.hidden = YES;
    dying.rootViewController = nil;
}

- (void)hf_matchFinishAfterMin:(void (^)(void))block {
    if (!block) return;
    // Keep matching popup until after navigation / result UI is applied (do not tear here).
    NSTimeInterval elapsed = CFAbsoluteTimeGetCurrent() - self.hf_matchShownAt;
    NSTimeInterval wait = MAX(0, kHFMatchMinShow - elapsed);
    if (wait <= 0) {
        block();
        return;
    }
    self.hf_pendingFinish = block;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        void (^fin)(void) = self.hf_pendingFinish;
        self.hf_pendingFinish = nil;
        if (fin) fin();
    });
}

- (void)hf_matchSetBackEnabled:(BOOL)on {
    self.hf_allowBack = on;
    if (on) {
        self.navigationItem.hidesBackButton = NO;
        [self hf_wireBackItem];
        self.navigationItem.leftBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = YES;
    }
}

#pragma mark - dcRecommend

- (void)hf_matchFire {
    if (self.hf_busy) return;
    self.hf_busy = YES;
    [self hf_matchSetBackEnabled:NO];
    self.hf_copyLab.hidden = YES;
    self.hf_viewNowBtn.hidden = YES;
    self.hf_iconIV.hidden = YES;
    [self hf_matchShowWin];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t work = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.hf_timeout = nil;
        if (!self.hf_busy) return;
        self.hf_busy = NO;
        [self hf_matchFinishAfterMin:^{
            [self hf_matchShowEmpty];
        }];
    });
    self.hf_timeout = work;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), work);

    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pDcRecommend]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelDcRecommendReply class]
                                   ok:^(HFParcelDcRecommendReply *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.hf_busy) return;
        [self hf_matchCancelTimeout];
        self.hf_busy = NO;
        NSArray *list = reply.data.productInfoList ?: @[];
        // Success but no products → rejectH5 if set, else no-product page.
        if (list.count == 0) {
            [self hf_matchFinishAfterMin:^{
                [self hf_matchOpenReject];
            }];
            return;
        }
        [self hf_matchFinishAfterMin:^{
            [self hf_matchOpenProducts:list];
        }];
    } fail:^(__unused NSString *msg, NSString * _Nullable code) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.hf_busy) return;
        [self hf_matchCancelTimeout];
        self.hf_busy = NO;
        // 4102007 / no product → rejectH5 if set, else no-product page.
        if ([code isEqualToString:[HFVaultSeal eDcNoProduct]]) {
            [self hf_matchFinishAfterMin:^{
                [self hf_matchOpenReject];
            }];
            return;
        }
        [self hf_matchFinishAfterMin:^{
            [self hf_matchShowOther];
        }];
    }];
}

- (void)hf_matchCancelTimeout {
    if (self.hf_timeout) {
        dispatch_block_cancel(self.hf_timeout);
        self.hf_timeout = nil;
    }
}

- (void)hf_matchShowEmpty {
    self.hf_copyLab.hidden = NO;
    self.hf_copyLab.text = kHFMatchEmptyCopy;
    self.hf_viewNowBtn.hidden = YES;
    self.hf_iconIV.hidden = NO;
    UIImage *icon = [UIImage imageNamed:@"dssl_bfh"];
    self.hf_iconIV.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.hf_iconIV.tintColor = [UIColor hf_prismHex:@"#C8C0B8"];
    [self hf_matchSetBackEnabled:YES];
    [self hf_matchTearWin];
}

/// 4102007 / empty list → rejectH5 when set; empty → original native empty page.
- (void)hf_matchOpenReject {
    [self hf_matchTearWin];
    [[HFOrbitHint shared] hf_orbitForceHaltSpin];

    NSString *h5 = [[HFLedgerFetch shared] hf_ledgerCache].dynamicParameter.rejectH5 ?: @"";
    h5 = [h5 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!h5.length) {
        [[HFLedgerFetch shared] hf_ledgerObtain:^(HFParcelConfig * _Nullable cfg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *url = [cfg.dynamicParameter.rejectH5
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
                [self hf_matchPushRejectURL:url];
            });
        }];
        return;
    }
    [self hf_matchPushRejectURL:h5];
}

- (void)hf_matchPushRejectURL:(NSString *)h5 {
    HFDriftNest *web = [HFDriftNest hf_driftWithURL:h5];
    if (!web) {
        // Core condition unmet → original flow (native no-product page).
        NSLog(@"[HFMatchNest] rejectH5 empty — fallback native empty page");
        [self hf_matchShowEmpty];
        return;
    }
    web.hidesBottomBarWhenPushed = YES;
    NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
    if (stack.count > 1) {
        [stack removeLastObject];
        [stack addObject:web];
        [self.navigationController setViewControllers:stack animated:YES];
    } else {
        [self.navigationController pushViewController:web animated:YES];
    }
}

- (void)hf_matchShowOther {
    NSString *copy = [self.hf_promptCopy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (!copy.length) copy = @"You have an outstanding loan. After repayment, products with higher limits will be available to you.";
    self.hf_copyLab.hidden = NO;
    self.hf_copyLab.text = copy;
    // Only userStatus=80 shows View Now >> (→ Pending Repayment). 100 etc.: text only.
    self.hf_viewNowBtn.hidden = (self.hf_userStatus != 80);
    self.hf_iconIV.hidden = NO;
    UIImage *icon = [UIImage imageNamed:@"dssl_dhk"];
    self.hf_iconIV.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.hf_iconIV.tintColor = [UIColor hf_prismHex:@"#C8C0B8"];
    [self hf_matchSetBackEnabled:YES];
    [self hf_matchTearWin];
}

- (void)hf_matchOpenProducts:(NSArray<HFParcelProductInfo *> *)list {
    if (list.count == 0) {
        [self hf_matchOpenReject];
        return;
    }
    // Tear matching dim BEFORE H5 loads — avoid stacking with HFOrbitHint Loading (0.7).
    [self hf_matchTearWin];
    [[HFOrbitHint shared] hf_orbitForceHaltSpin];

    // 贷超升级多产品由 H5 自理：不传 productId，仅通用登录态；申请页识别靠产品申请 URL。
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initH5WithURLString:[HFVaultSeal kHrefProductApply]
                                                            title:nil
                                                           extras:@{}];
    web.hidesBottomBarWhenPushed = YES;
    NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
    if (stack.count > 1) {
        [stack removeLastObject];
        [stack addObject:web];
        [self.navigationController setViewControllers:stack animated:YES];
    } else {
        [self.navigationController pushViewController:web animated:YES];
    }
}

/// View Now：仅 userStatus=80 → 待还款订单列表
- (void)hf_matchTapViewNow {
    if (self.hf_userStatus != 80) return;
    [self hf_matchJumpOrder:20]; // Pending Repayment
}

- (void)hf_matchJumpOrder:(NSInteger)orderStatus {
    HFDockBar *bar = nil;
    if ([self.tabBarController isKindOfClass:[HFDockBar class]]) {
        bar = (HFDockBar *)self.tabBarController;
    } else {
        UIViewController *p = self.parentViewController;
        while (p) {
            if ([p isKindOfClass:[HFDockBar class]]) {
                bar = (HFDockBar *)p;
                break;
            }
            p = p.parentViewController;
        }
    }
    [self.navigationController popToRootViewControllerAnimated:NO];
    [bar hf_dockSelectOrderStatus:orderStatus];
}

@end
