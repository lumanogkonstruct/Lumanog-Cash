#import "HFAmberNest.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFQuillVault.h"
#import "HFCurtainBox.h"
#import "HFParcelBase.h"
#import "SceneDelegate.h"
#import <Masonry/Masonry.h>

@interface HFAmberNest ()
@property (nonatomic, strong) UIView *hf_band;
@property (nonatomic, strong) UIImageView *hf_mark;
@property (nonatomic, strong) UILabel *hf_nameLab;
@property (nonatomic, strong) UILabel *hf_verLab;
@property (nonatomic, strong) UILabel *hf_descLab;
@property (nonatomic, strong) UIButton *hf_delBtn;
@end

@implementation HFAmberNest

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"About";
    self.title = self.hf_navTitle;
    [self hf_buildChrome];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - UI

- (void)hf_buildChrome {
    self.hf_band = [UIView new];
    self.hf_band.backgroundColor = [UIColor hf_prismInk];
    [self.view addSubview:self.hf_band];

    self.hf_mark = [UIImageView new];
    self.hf_mark.backgroundColor = UIColor.whiteColor;
    self.hf_mark.image = [UIImage imageNamed:@"logo"];
    self.hf_mark.contentMode = UIViewContentModeScaleAspectFill;
    self.hf_mark.clipsToBounds = YES;
    self.hf_mark.layer.cornerRadius = 28;
    [self.hf_band addSubview:self.hf_mark];

    self.hf_nameLab = [UILabel new];
    self.hf_nameLab.text = [self hf_appName];
    self.hf_nameLab.textColor = UIColor.whiteColor;
    self.hf_nameLab.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightRegular];
    [self.hf_band addSubview:self.hf_nameLab];

    self.hf_verLab = [UILabel new];
    self.hf_verLab.text = [self hf_appVersion];
    self.hf_verLab.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    self.hf_verLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    self.hf_verLab.textAlignment = NSTextAlignmentRight;
    [self.hf_band addSubview:self.hf_verLab];

    self.hf_descLab = [UILabel new];
    self.hf_descLab.text = [self hf_appDesc];
    self.hf_descLab.textColor = UIColor.whiteColor;
    self.hf_descLab.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    self.hf_descLab.numberOfLines = 0;
    [self.hf_band addSubview:self.hf_descLab];

    self.hf_delBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hf_delBtn.backgroundColor = UIColor.whiteColor;
    self.hf_delBtn.layer.cornerRadius = 28;
    [self.hf_delBtn setTitle:@"Delete Account" forState:UIControlStateNormal];
    [self.hf_delBtn setTitleColor:[UIColor hf_prismTheme] forState:UIControlStateNormal];
    self.hf_delBtn.titleLabel.font = [UIFont hf_latticeGlyph:17 mass:UIFontWeightRegular];
    [self.hf_delBtn addTarget:self action:@selector(hf_tapDelete) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.hf_delBtn];

    [self.hf_band mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
    }];
    [self.hf_mark mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.leading.equalTo(self.hf_band).offset(24);
        make.width.height.mas_equalTo(56);
    }];
    [self.hf_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.hf_mark);
        make.leading.equalTo(self.hf_mark.mas_trailing).offset(12);
    }];
    [self.hf_verLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.hf_mark);
        make.trailing.equalTo(self.hf_band).offset(-24);
        make.leading.greaterThanOrEqualTo(self.hf_nameLab.mas_trailing).offset(8);
    }];
    [self.hf_nameLab setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.hf_verLab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.hf_descLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_mark.mas_bottom).offset(20);
        make.leading.equalTo(self.hf_band).offset(24);
        make.trailing.equalTo(self.hf_band).offset(-24);
        make.bottom.equalTo(self.hf_band).offset(-28);
    }];

    [self.hf_delBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(56);
    }];
}

- (NSString *)hf_appName {
    NSString *n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!n.length) n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return n.length ? n : @"App";
}

- (NSString *)hf_appVersion {
    NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (!v.length) v = @"1.0.0";
    return [NSString stringWithFormat:@"V %@", v];
}

- (NSString *)hf_appDesc {
    // Design shows multi-line intro under the brand row; keep concise product copy.
    return @"Lumanog Cash redefines convenient borrowing, merging transparent policies, speedy processing and trustworthy user protection.";
}

#pragma mark - Delete account

- (NSString *)hf_confirmBody {
    return @"When your loan order is under review and loan processing, you cannot cancel your account.\n\nWhen your loan order has not been settled, you cannot cancel your account.\n\nAfter confirming the cancellation, the account will not be restored. Please operate with caution.";
}

- (void)hf_tapDelete {
    __weak typeof(self) weakSelf = self;
    HFCurtainSheet *s = [HFCurtainSheet new];
    s.titleText = @"Delete account";
    s.bodyText = [self hf_confirmBody];
    s.leftTitle = @"Confirm";
    s.rightTitle = @"Cancel";
    s.tier = HFCurtainTierMid;
    s.onLeft = ^{
        [weakSelf hf_requestClose];
    };
    s.onRight = nil;
    [[HFCurtainBox shared] hf_curtainSheet:s];
}

- (void)hf_requestClose {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pAuthClose]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelBase class]
                                   ok:^(__unused HFParcelBase *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [HFQuillVault hf_quillErase];
        HFCurtainSheet *s = [HFCurtainSheet new];
        s.titleText = @"Success!";
        s.bodyText = @"Account cancelled successfully.";
        s.rightTitle = @"Confirm";
        s.tier = HFCurtainTierMid;
        s.onRight = ^{
            [self hf_goGate];
        };
        [[HFCurtainBox shared] hf_curtainSheet:s];
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        HFCurtainSheet *s = [HFCurtainSheet new];
        s.titleText = @"Failed!";
        s.bodyText = @"Account cancellation failed, please check your order.";
        s.rightTitle = @"Confirm";
        s.tier = HFCurtainTierMid;
        [[HFCurtainBox shared] hf_curtainSheet:s];
    }];
}

- (void)hf_goGate {
    id<UISceneDelegate> del = self.view.window.windowScene.delegate;
    if ([del isKindOfClass:[SceneDelegate class]]) {
        [(SceneDelegate *)del hf_sceneShowGate];
        return;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene.delegate isKindOfClass:[SceneDelegate class]]) {
            [(SceneDelegate *)scene.delegate hf_sceneShowGate];
            return;
        }
    }
}

@end
