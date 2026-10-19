#import "HFBeaconNest.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import "HFLedgerFetch.h"
#import "HFParcelModels.h"
#import <Masonry/Masonry.h>

@interface HFBeaconNest ()
@property (nonatomic, strong) UIScrollView *hf_scroll;
@property (nonatomic, strong) UIView *hf_content;
@property (nonatomic, strong) UILabel *hf_introLab;
@property (nonatomic, strong) UILabel *hf_linkCaption;
@property (nonatomic, strong) UIView *hf_linkCard;
@property (nonatomic, strong) UILabel *hf_linkValue;
@property (nonatomic, strong) UIImageView *hf_copyIcon;
@property (nonatomic, copy) NSString *hf_linkText;
@end

@implementation HFBeaconNest

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"Official Website";
    self.title = self.hf_navTitle;
    self.hf_linkText = @"";
    [self hf_beaconBuildChrome];
    [self hf_beaconLoadConfig];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - UI

- (void)hf_beaconBuildChrome {
    UIColor *ink = [UIColor hf_prismInk];
    UIColor *muted = [UIColor hf_prismHex:@"#8A8178"];

    self.hf_scroll = [UIScrollView new];
    self.hf_scroll.alwaysBounceVertical = YES;
    self.hf_scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.hf_scroll];

    self.hf_content = [UIView new];
    [self.hf_scroll addSubview:self.hf_content];

    self.hf_introLab = [UILabel new];
    self.hf_introLab.numberOfLines = 0;
    self.hf_introLab.textColor = ink;
    self.hf_introLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    self.hf_introLab.text = @"When encountering issues with your app, you can also apply and repay through the official website. We recommend that you save the official website address:";
    [self.hf_content addSubview:self.hf_introLab];

    self.hf_linkCaption = [UILabel new];
    self.hf_linkCaption.text = @"Official website link";
    self.hf_linkCaption.textColor = muted;
    self.hf_linkCaption.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    self.hf_linkCaption.textAlignment = NSTextAlignmentCenter;
    [self.hf_content addSubview:self.hf_linkCaption];

    self.hf_linkCard = [UIView new];
    self.hf_linkCard.backgroundColor = UIColor.whiteColor;
    self.hf_linkCard.layer.cornerRadius = 26;
    self.hf_linkCard.userInteractionEnabled = YES;
    [self.hf_content addSubview:self.hf_linkCard];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hf_beaconTapCopy)];
    [self.hf_linkCard addGestureRecognizer:tap];

    self.hf_linkValue = [UILabel new];
    self.hf_linkValue.textColor = ink;
    self.hf_linkValue.font = [UIFont hf_latticeGlyph:15 mass:UIFontWeightRegular];
    self.hf_linkValue.numberOfLines = 0;
    self.hf_linkValue.userInteractionEnabled = NO;
    [self.hf_linkCard addSubview:self.hf_linkValue];

    self.hf_copyIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"one_icon_copy"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    self.hf_copyIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.hf_copyIcon.userInteractionEnabled = NO;
    [self.hf_linkCard addSubview:self.hf_copyIcon];

    [self.hf_scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.hf_content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.hf_scroll);
        make.width.equalTo(self.hf_scroll);
    }];
    [self.hf_introLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_content).offset(28);
        make.leading.equalTo(self.hf_content).offset(24);
        make.trailing.equalTo(self.hf_content).offset(-24);
    }];
    [self.hf_linkCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_introLab.mas_bottom).offset(28);
        make.leading.trailing.equalTo(self.hf_introLab);
    }];
    [self.hf_linkCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_linkCaption.mas_bottom).offset(12);
        make.leading.equalTo(self.hf_content).offset(24);
        make.trailing.equalTo(self.hf_content).offset(-24);
        make.height.mas_greaterThanOrEqualTo(52);
        make.bottom.equalTo(self.hf_content).offset(-32);
    }];
    [self.hf_copyIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.hf_linkCard).offset(-16);
        make.centerY.equalTo(self.hf_linkCard);
        make.width.height.mas_equalTo(22);
    }];
    [self.hf_linkValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.hf_linkCard).offset(18);
        make.trailing.equalTo(self.hf_copyIcon.mas_leading).offset(-10);
        make.top.equalTo(self.hf_linkCard).offset(14);
        make.bottom.equalTo(self.hf_linkCard).offset(-14);
    }];

    [self hf_beaconApplyLink];
}

- (void)hf_beaconApplyLink {
    NSString *t = [self.hf_linkText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.hf_linkValue.text = t.length ? t : @"Not available";
}

#pragma mark - Data

- (void)hf_beaconLoadConfig {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFLedgerFetch shared] hf_ledgerObtain:^(HFParcelConfig * _Nullable cfg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [[HFOrbitHint shared] hf_orbitHaltSpin];
            if (!cfg) {
                [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
                self.hf_linkText = @"";
                [self hf_beaconApplyLink];
                return;
            }
            self.hf_linkText = cfg.officialWebsiteUrl ?: @"";
            [self hf_beaconApplyLink];
        });
    }];
}

#pragma mark - Copy (whole card)

- (void)hf_beaconTapCopy {
    NSString *t = [self.hf_linkText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!t.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    UIPasteboard.generalPasteboard.string = t;
    [[HFOrbitHint shared] hf_orbitPulse:@"The link has been copied to the clipboard."];
}

@end
