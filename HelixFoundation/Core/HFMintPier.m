#import "HFMintPier.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFParcelModels.h"
#import "HFLedgerFetch.h"
#import "HFPaneBrowse.h"
#import <Masonry/Masonry.h>

@interface HFMintPier ()
@property (nonatomic, strong) UILabel *hf_tipLab;
@property (nonatomic, strong) UIScrollView *hf_scroll;
@property (nonatomic, strong) UIStackView *hf_stack;
@property (nonatomic, strong) UIView *hf_emptyBlock;
@property (nonatomic, strong) UIImageView *hf_emptyPic;
@property (nonatomic, strong) UILabel *hf_emptyLab;
@property (nonatomic, strong) UIButton *hf_addBtn;
@property (nonatomic, strong) NSArray<HFParcelPayAccount *> *hf_list;
@end

@implementation HFMintPier

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"Bank Account";
    self.title = self.hf_navTitle;
    self.hf_list = @[];
    [self hf_mintBuildChrome];
    [self hf_mintRender];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self hf_mintReload];
}

#pragma mark - UI

- (void)hf_mintBuildChrome {
    UIColor *ink = [UIColor hf_prismInk];

    self.hf_tipLab = [UILabel new];
    self.hf_tipLab.numberOfLines = 0;
    self.hf_tipLab.textColor = ink;
    self.hf_tipLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    // Design copy (list tip).
    self.hf_tipLab.text = @"You may link multiple receiving accounts. If the default account is unavailable, we will automatically switch to the backup account to ensure a successful disbursement.";
    [self.view addSubview:self.hf_tipLab];

    self.hf_scroll = [UIScrollView new];
    self.hf_scroll.alwaysBounceVertical = YES;
    self.hf_scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.hf_scroll];

    self.hf_stack = [[UIStackView alloc] init];
    self.hf_stack.axis = UILayoutConstraintAxisVertical;
    self.hf_stack.spacing = 12;
    [self.hf_scroll addSubview:self.hf_stack];

    self.hf_emptyBlock = [UIView new];
    [self.view addSubview:self.hf_emptyBlock];
    self.hf_emptyPic = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"one_pic_02"]];
    self.hf_emptyPic.contentMode = UIViewContentModeScaleAspectFit;
    [self.hf_emptyBlock addSubview:self.hf_emptyPic];
    self.hf_emptyLab = [UILabel new];
    self.hf_emptyLab.text = @"No bank account";
    self.hf_emptyLab.textColor = [UIColor hf_prismHex:@"#B8AFA6"];
    self.hf_emptyLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    self.hf_emptyLab.textAlignment = NSTextAlignmentCenter;
    [self.hf_emptyBlock addSubview:self.hf_emptyLab];

    self.hf_addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hf_addBtn.backgroundColor = [UIColor hf_prismTheme];
    self.hf_addBtn.layer.cornerRadius = 28;
    [self.hf_addBtn setTitle:@"Add" forState:UIControlStateNormal];
    [self.hf_addBtn setTitleColor:ink forState:UIControlStateNormal];
    self.hf_addBtn.titleLabel.font = [UIFont hf_latticeGlyph:17 mass:UIFontWeightRegular];
    [self.hf_addBtn addTarget:self action:@selector(hf_mintTapAdd) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.hf_addBtn];

    [self.hf_addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(56);
    }];
    [self.hf_tipLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(16);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];
    [self.hf_scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_tipLab.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.hf_addBtn.mas_top).offset(-12);
    }];
    [self.hf_stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.hf_scroll).insets(UIEdgeInsetsMake(0, 16, 16, 16));
        make.width.equalTo(self.hf_scroll).offset(-32);
    }];
    [self.hf_emptyBlock mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_tipLab.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.hf_addBtn.mas_top);
    }];
    [self.hf_emptyPic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.hf_emptyBlock);
        make.centerY.equalTo(self.hf_emptyBlock).offset(-20);
        make.width.height.mas_equalTo(90);
    }];
    [self.hf_emptyLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_emptyPic.mas_bottom).offset(12);
        make.centerX.equalTo(self.hf_emptyBlock);
        make.leading.greaterThanOrEqualTo(self.hf_emptyBlock).offset(24);
        make.trailing.lessThanOrEqualTo(self.hf_emptyBlock).offset(-24);
    }];
}

#pragma mark - Data

- (void)hf_mintReload {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pPayAccountList]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelPayAccountListReply class]
                                   ok:^(HFParcelPayAccountListReply *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        if (!self) return;
        self.hf_list = reply.data.payAccountInfoList ?: @[];
        [self hf_mintRender];
    } fail:^(NSString * _Nullable msg, __unused NSString *code) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        if (!self) return;
        self.hf_list = @[];
        [self hf_mintRender];
        NSString *toast = msg.length ? msg : @"Failed to load bank cards";
        [[HFOrbitHint shared] hf_orbitPulse:toast];
    }];
}

- (void)hf_mintRender {
    BOOL has = self.hf_list.count > 0;
    self.hf_scroll.hidden = !has;
    self.hf_emptyBlock.hidden = has;
    for (UIView *v in self.hf_stack.arrangedSubviews) {
        [self.hf_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    if (!has) return;
    for (NSInteger i = 0; i < (NSInteger)self.hf_list.count; i++) {
        [self.hf_stack addArrangedSubview:[self hf_mintCard:self.hf_list[i] index:i]];
    }
}

#pragma mark - Card

- (NSString *)hf_mintGroupedAccount:(NSString *)raw {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) return @"XXXX  XXXX  XXXX  XXXX";
    NSMutableString *digits = [NSMutableString string];
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
            [digits appendFormat:@"%C", c];
        }
    }
    if (digits.length == 0) return raw;
    NSMutableString *out = [NSMutableString string];
    for (NSUInteger i = 0; i < digits.length; i++) {
        if (i > 0 && i % 4 == 0) [out appendString:@"  "];
        [out appendFormat:@"%C", [digits characterAtIndex:i]];
    }
    return out;
}

- (UIView *)hf_mintCard:(HFParcelPayAccount *)item index:(NSInteger)index {
    UIView *card = [UIView new];
    card.clipsToBounds = YES;
    card.layer.cornerRadius = 16;
    card.tag = index;

    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card"]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    bg.clipsToBounds = YES;
    [card addSubview:bg];

    UILabel *bank = [UILabel new];
    NSString *bn = item.bankName.length ? item.bankName : (item.bankCode ?: @"");
    bank.text = bn.length ? bn : @"--";
    bank.textColor = UIColor.whiteColor;
    bank.font = [UIFont hf_latticeGlyph:12 mass:UIFontWeightRegular];
    [card addSubview:bank];

    UILabel *name = [UILabel new];
    name.text = item.accountName.length ? item.accountName : @"user name";
    name.textColor = UIColor.whiteColor;
    name.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    name.numberOfLines = 1;
    [card addSubview:name];

    UILabel *acc = [UILabel new];
    acc.text = [self hf_mintGroupedAccount:item.accountNo];
    acc.textColor = UIColor.whiteColor;
    acc.font = [UIFont hf_latticeGlyph:18 mass:UIFontWeightMedium];
    acc.adjustsFontSizeToFitWidth = YES;
    acc.minimumScaleFactor = 0.7;
    [card addSubview:acc];

    BOOL isDefault = [item.defaultFlag isEqualToString:@"1"];
    UIButton *defBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    defBtn.tag = index;
    NSString *icon = isDefault ? @"make_icon_white_not" : @"make_icon_sel_not";
    [defBtn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [defBtn setTitle:@"  Default" forState:UIControlStateNormal];
    [defBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    defBtn.titleLabel.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    defBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [defBtn addTarget:self action:@selector(hf_mintTapDefault:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:defBtn];

    BOOL canEdit = [item.editFlag isEqualToString:@"1"];
    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    editBtn.tag = index;
    [editBtn setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
    editBtn.alpha = canEdit ? 1.0 : 0.35;
    editBtn.userInteractionEnabled = canEdit;
    [editBtn addTarget:self action:@selector(hf_mintTapEdit:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:editBtn];

    if (canEdit) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hf_mintTapCard:)];
        card.userInteractionEnabled = YES;
        [card addGestureRecognizer:tap];
    }

    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card);
    }];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(180);
    }];
    [bank mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(18);
        make.leading.equalTo(card).offset(18);
        make.trailing.equalTo(card).offset(-18);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bank.mas_bottom).offset(10);
        make.leading.trailing.equalTo(bank);
    }];
    [acc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(name.mas_bottom).offset(14);
        make.leading.trailing.equalTo(bank);
    }];
    [defBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(card).offset(14);
        make.bottom.equalTo(card).offset(-16);
        make.height.mas_equalTo(28);
    }];
    [editBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(card).offset(-16);
        make.centerY.equalTo(defBtn);
        make.width.height.mas_equalTo(28);
    }];
    return card;
}

#pragma mark - Actions

- (HFParcelPayAccount *)hf_mintItemAt:(NSInteger)idx {
    if (idx < 0 || idx >= (NSInteger)self.hf_list.count) return nil;
    return self.hf_list[idx];
}

- (void)hf_mintTapDefault:(UIButton *)sender {
    HFParcelPayAccount *item = [self hf_mintItemAt:sender.tag];
    if (!item) return;
    if ([item.defaultFlag isEqualToString:@"1"]) return;
    if (!item.recordId.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Failed to update default account"];
        return;
    }
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pPayAccountUpdate]
                              signMap:@{}
                           nonSignMap:@{ @"recordId": item.recordId ?: @"", @"defaultFlag": @"1" }
                           replyClass:[HFParcelBase class]
                                   ok:^(__unused HFParcelBase *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        if (!self) return;
        [self hf_mintReload];
    } fail:^(NSString * _Nullable msg, __unused NSString *code) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        [[HFOrbitHint shared] hf_orbitPulse:msg.length ? msg : @"Failed to update default account"];
    }];
}

- (void)hf_mintOpenBankH5:(nullable NSString *)bindId {
    NSString *link = [[HFVaultSeal kHrefUpdateBank] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (!link.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    NSMutableDictionary *extras = [NSMutableDictionary dictionary];
    if (bindId.length) extras[@"bindId"] = bindId;
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initH5WithURLString:link title:nil extras:extras];
    web.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:web animated:YES];
}

- (void)hf_mintOpenEdit:(HFParcelPayAccount *)item {
    if (![item.editFlag isEqualToString:@"1"]) return;
    NSString *bindId = item.bankCardBindId.length ? item.bankCardBindId : item.recordId;
    if (!bindId.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    [self hf_mintOpenBankH5:bindId];
}

- (void)hf_mintTapEdit:(UIButton *)sender {
    HFParcelPayAccount *item = [self hf_mintItemAt:sender.tag];
    if (item) [self hf_mintOpenEdit:item];
}

- (void)hf_mintTapCard:(UITapGestureRecognizer *)tap {
    NSInteger idx = tap.view.tag;
    HFParcelPayAccount *item = [self hf_mintItemAt:idx];
    if (item) [self hf_mintOpenEdit:item];
}

- (void)hf_mintTapAdd {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pKycFourStatus]
                              signMap:@{}
                           nonSignMap:@{}
                            dataClass:[HFParcelKycStatus class]
                                   ok:^(HFParcelKycStatus *status) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        if (!self) return;
        NSString *step = [status hf_willExecuteStep];
        if ([step integerValue] == -1 || [step isEqualToString:@"-1"]) {
            [self hf_mintOpenBankH5:nil];
            return;
        }
        [[HFOrbitHint shared] hf_orbitPulse:@"You need to finish KYC verification to add a bank account."];
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
    }];
}

@end
