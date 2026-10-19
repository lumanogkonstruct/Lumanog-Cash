#import "HFDockLeaf.h"
#import "HFLatticeKit.h"
#import "HFOrbitHint.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFQuillVault.h"
#import "HFLedgerFetch.h"
#import "HFPaneBrowse.h"
#import "HFCurtainBox.h"
#import "HFParcelModels.h"
#import "HFRelayNote.h"
#import "HFAmberNest.h"
#import "HFDriftNest.h"
#import "SceneDelegate.h"
#import <Masonry/Masonry.h>

static const NSTimeInterval kHFMePushGap = 0.8;

#pragma mark - Order cell

@interface HFOrbitCardCell : UITableViewCell
@property (nonatomic, strong) UIView *hf_card;
@property (nonatomic, strong) UILabel *hf_statusLab;
@property (nonatomic, strong) UIView *hf_infoBox;
@property (nonatomic, strong) UILabel *hf_k1;
@property (nonatomic, strong) UILabel *hf_v1;
@property (nonatomic, strong) UILabel *hf_k2;
@property (nonatomic, strong) UILabel *hf_v2;
@property (nonatomic, strong) UILabel *hf_nameLab;
@property (nonatomic, strong) UILabel *hf_amountLab;
- (void)hf_bind:(HFParcelOrderItem *)item;
@end

@implementation HFOrbitCardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        self.hf_card = [UIView new];
        self.hf_card.backgroundColor = UIColor.whiteColor;
        self.hf_card.layer.cornerRadius = 16;
        [self.contentView addSubview:self.hf_card];

        self.hf_statusLab = [UILabel new];
        self.hf_statusLab.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightMedium];
        self.hf_statusLab.textAlignment = NSTextAlignmentCenter;
        [self.hf_card addSubview:self.hf_statusLab];

        self.hf_infoBox = [UIView new];
        self.hf_infoBox.backgroundColor = [UIColor hf_prismHex:@"#F5EDE2"];
        self.hf_infoBox.layer.cornerRadius = 12;
        [self.hf_card addSubview:self.hf_infoBox];

        self.hf_k1 = [self hf_metaLab:YES];
        self.hf_v1 = [self hf_metaLab:NO];
        self.hf_k2 = [self hf_metaLab:YES];
        self.hf_v2 = [self hf_metaLab:NO];
        [self.hf_infoBox addSubview:self.hf_k1];
        [self.hf_infoBox addSubview:self.hf_v1];
        [self.hf_infoBox addSubview:self.hf_k2];
        [self.hf_infoBox addSubview:self.hf_v2];

        self.hf_nameLab = [UILabel new];
        self.hf_nameLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
        self.hf_nameLab.textColor = [UIColor hf_prismInk];
        [self.hf_card addSubview:self.hf_nameLab];

        self.hf_amountLab = [UILabel new];
        self.hf_amountLab.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightMedium];
        self.hf_amountLab.textColor = [UIColor hf_prismInk];
        self.hf_amountLab.textAlignment = NSTextAlignmentRight;
        [self.hf_card addSubview:self.hf_amountLab];

        [self.hf_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.leading.equalTo(self.contentView).offset(16);
            make.trailing.equalTo(self.contentView).offset(-16);
            make.bottom.equalTo(self.contentView).offset(-12);
        }];
        [self.hf_statusLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_card).offset(16);
            make.leading.trailing.equalTo(self.hf_card).inset(12);
        }];
        [self.hf_infoBox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_statusLab.mas_bottom).offset(12);
            make.leading.trailing.equalTo(self.hf_card).inset(12);
        }];
        [self.hf_k1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_infoBox).offset(12);
            make.leading.equalTo(self.hf_infoBox).offset(12);
        }];
        [self.hf_v1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.hf_k1);
            make.trailing.equalTo(self.hf_infoBox).offset(-12);
            make.leading.greaterThanOrEqualTo(self.hf_k1.mas_trailing).offset(8);
        }];
        [self.hf_k2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_k1.mas_bottom).offset(10);
            make.leading.equalTo(self.hf_k1);
            make.bottom.equalTo(self.hf_infoBox).offset(-12);
        }];
        [self.hf_v2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.hf_k2);
            make.trailing.equalTo(self.hf_v1);
            make.leading.greaterThanOrEqualTo(self.hf_k2.mas_trailing).offset(8);
        }];
        [self.hf_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.hf_infoBox.mas_bottom).offset(14);
            make.leading.equalTo(self.hf_card).offset(16);
            make.bottom.equalTo(self.hf_card).offset(-16);
        }];
        [self.hf_amountLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.hf_nameLab);
            make.trailing.equalTo(self.hf_card).offset(-16);
            make.leading.greaterThanOrEqualTo(self.hf_nameLab.mas_trailing).offset(8);
        }];
        [self.hf_nameLab setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.hf_amountLab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    return self;
}

- (UILabel *)hf_metaLab:(BOOL)key {
    UILabel *lab = [UILabel new];
    lab.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    lab.textColor = key ? [UIColor hf_prismHex:@"#9A8F86"] : [UIColor hf_prismInk];
    if (!key) lab.textAlignment = NSTextAlignmentRight;
    return lab;
}

+ (NSString *)hf_dash:(NSString *)s {
    NSString *t = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return t.length ? t : @"-";
}

+ (NSString *)hf_statusTitle:(NSInteger)st {
    switch (st) {
        case 10: return @"Unfinished Application";
        case 30: return @"Under review";
        case 31: return @"Reject";
        case 32: return @"To be withdrawn";
        case 36: return @"Change bank account";
        case 50: return @"Loan processing";
        case 60: return @"Pending Repayment";
        case 61: return @"Overdue";
        case 70: return @"Pay off";
        case 99: return @"Cancel";
        default: return @"-";
    }
}

+ (UIColor *)hf_statusColor:(NSInteger)st {
    switch (st) {
        case 10: return [UIColor hf_prismHex:@"#978CFF"];
        case 30: return [UIColor hf_prismHex:@"#EFA37A"];
        case 31: return [UIColor hf_prismHex:@"#FF2727"];
        case 32: return [UIColor hf_prismHex:@"#EF7AC2"];
        case 36: return [UIColor hf_prismHex:@"#79CD61"];
        case 50: return [UIColor hf_prismHex:@"#08A3BF"];
        case 60: return [UIColor hf_prismHex:@"#A1CCD1"];
        case 61: return [UIColor hf_prismHex:@"#D26FFF"];
        case 70: return [UIColor hf_prismHex:@"#0091FF"];
        case 99: return [UIColor hf_prismHex:@"#9F9F9F"];
        default: return [UIColor hf_prismInk];
    }
}

+ (NSString *)hf_peso:(NSInteger)amount {
    NSNumberFormatter *fmt = [NSNumberFormatter new];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    fmt.maximumFractionDigits = 0;
    fmt.minimumFractionDigits = 0;
    NSString *num = [fmt stringFromNumber:@(amount)] ?: @"0";
    return [NSString stringWithFormat:@"₱ %@", num];
}

- (void)hf_bind:(HFParcelOrderItem *)item {
    NSInteger st = item.orderStatus;
    self.hf_statusLab.text = [self.class hf_statusTitle:st];
    self.hf_statusLab.textColor = [self.class hf_statusColor:st];

    if (st == 60 || st == 61) {
        self.hf_k1.text = @"Payment date";
        self.hf_v1.text = [self.class hf_dash:item.loanDate];
        self.hf_k2.text = @"Due date";
        self.hf_v2.text = [self.class hf_dash:item.dueDate];
    } else if (st == 70) {
        self.hf_k1.text = @"Payment date";
        self.hf_v1.text = [self.class hf_dash:item.loanDate];
        self.hf_k2.text = @"Repayment date";
        self.hf_v2.text = [self.class hf_dash:item.repayDate];
    } else {
        self.hf_k1.text = @"Date of application";
        self.hf_v1.text = [self.class hf_dash:item.applyDate];
        self.hf_k2.text = @"Due date";
        self.hf_v2.text = [self.class hf_dash:item.dueDate];
    }
    NSString *name = [item.productName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.hf_nameLab.text = name.length ? name : @"-";
    self.hf_amountLab.text = [self.class hf_peso:item.loanAmount];
}

@end

#pragma mark - Order Tab

@interface HFDockLeafOrder () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UILabel *hf_titleLab;
@property (nonatomic, strong) UIStackView *hf_chipGrid; // 2 rows × 2 equal columns
@property (nonatomic, strong) NSArray<UIButton *> *hf_chips;
@property (nonatomic, strong) UITableView *hf_table;
@property (nonatomic, strong) UIView *hf_empty;
@property (nonatomic, strong) NSArray<HFParcelOrderItem *> *hf_rows;
@property (nonatomic, assign) NSInteger hf_filterStatus; // 20/10/30/40
@property (nonatomic, assign) BOOL hf_appeared;
@end

@implementation HFDockLeafOrder

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _hf_filterStatus = 20;
        _hf_rows = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"";
    self.hf_canvasTint = [UIColor hf_prismInk];
    [self hf_applyCanvas];
    // Keep hf_filterStatus from hf_orderFocusStatus (do not reset to 20 here).
    if (!self.hf_rows) self.hf_rows = @[];
    [self hf_orderBuild];
    [self hf_orderSyncChips];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.hf_appeared = YES;
    [self hf_orderSyncChips];
    [self hf_orderReload];
}

- (void)hf_orderFocusStatus:(NSInteger)orderStatus {
    NSInteger st = orderStatus;
    if (st != 20 && st != 10 && st != 30 && st != 40) st = 20;
    self.hf_filterStatus = st;
    if (!self.isViewLoaded) return;
    [self hf_orderSyncChips];
    if (self.hf_appeared) {
        [self hf_orderReload];
    }
}

- (UIButton *)hf_orderMakeChip:(NSString *)title status:(NSInteger)status {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.tag = status;
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    b.titleLabel.minimumScaleFactor = 0.85;
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    b.contentEdgeInsets = UIEdgeInsetsMake(10, 8, 10, 8);
    b.layer.cornerRadius = 10;
    b.clipsToBounds = YES;
    [b addTarget:self action:@selector(hf_orderTapChip:) forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)hf_orderBuild {
    self.hf_titleLab = [UILabel new];
    self.hf_titleLab.text = @"Order history";
    self.hf_titleLab.textColor = [UIColor hf_prismTheme];
    self.hf_titleLab.font = [UIFont hf_latticeGlyph:28 mass:UIFontWeightBold];
    [self.view addSubview:self.hf_titleLab];

    // 2 rows × 2 columns, equal width
    NSArray *defs = @[
        @{ @"t": @"Pending Repayment", @"s": @20 },
        @{ @"t": @"Submit Application", @"s": @10 },
        @{ @"t": @"Processing", @"s": @30 },
        @{ @"t": @"Completed", @"s": @40 },
    ];
    NSMutableArray *btns = [NSMutableArray array];
    for (NSDictionary *d in defs) {
        [btns addObject:[self hf_orderMakeChip:d[@"t"] status:[d[@"s"] integerValue]]];
    }
    self.hf_chips = btns;

    UIStackView *row1 = [[UIStackView alloc] initWithArrangedSubviews:@[btns[0], btns[1]]];
    row1.axis = UILayoutConstraintAxisHorizontal;
    row1.spacing = 10;
    row1.distribution = UIStackViewDistributionFillEqually;
    row1.alignment = UIStackViewAlignmentFill;

    UIStackView *row2 = [[UIStackView alloc] initWithArrangedSubviews:@[btns[2], btns[3]]];
    row2.axis = UILayoutConstraintAxisHorizontal;
    row2.spacing = 10;
    row2.distribution = UIStackViewDistributionFillEqually;
    row2.alignment = UIStackViewAlignmentFill;

    self.hf_chipGrid = [[UIStackView alloc] initWithArrangedSubviews:@[row1, row2]];
    self.hf_chipGrid.axis = UILayoutConstraintAxisVertical;
    self.hf_chipGrid.spacing = 10;
    self.hf_chipGrid.distribution = UIStackViewDistributionFillEqually;
    self.hf_chipGrid.alignment = UIStackViewAlignmentFill;
    [self.view addSubview:self.hf_chipGrid];

    self.hf_table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.hf_table.backgroundColor = UIColor.clearColor;
    self.hf_table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.hf_table.delegate = self;
    self.hf_table.dataSource = self;
    self.hf_table.rowHeight = UITableViewAutomaticDimension;
    self.hf_table.estimatedRowHeight = 180;
    self.hf_table.contentInset = UIEdgeInsetsMake(8, 0, 16, 0);
    [self.hf_table registerClass:[HFOrbitCardCell class] forCellReuseIdentifier:@"c"];
    [self.view addSubview:self.hf_table];

    self.hf_empty = [UIView new];
    self.hf_empty.hidden = YES;
    [self.view addSubview:self.hf_empty];
    UIImageView *pic = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"one_pic_01"]];
    pic.contentMode = UIViewContentModeScaleAspectFit;
    [self.hf_empty addSubview:pic];
    UILabel *emptyLab = [UILabel new];
    emptyLab.text = @"No order";
    emptyLab.textColor = UIColor.whiteColor;
    emptyLab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    emptyLab.textAlignment = NSTextAlignmentCenter;
    [self.hf_empty addSubview:emptyLab];
    [pic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.equalTo(self.hf_empty);
        make.width.height.mas_equalTo(90);
    }];
    [emptyLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pic.mas_bottom).offset(12);
        make.leading.trailing.bottom.equalTo(self.hf_empty);
    }];

    [self.hf_titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
    }];
    [self.hf_chipGrid mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_titleLab.mas_bottom).offset(16);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(88); // 2 rows × ~39 + spacing
    }];
    [self.hf_table mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hf_chipGrid.mas_bottom).offset(8);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
    [self.hf_empty mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(20);
        make.leading.greaterThanOrEqualTo(self.view).offset(40);
        make.trailing.lessThanOrEqualTo(self.view).offset(-40);
    }];
}

- (void)hf_orderSyncChips {
    UIColor *ink = [UIColor hf_prismInk];
    UIColor *sel = [UIColor hf_prismTheme]; // #EFA37A
    UIColor *unsel = [UIColor hf_prismHex:@"#9F9F9F"];
    for (UIButton *b in self.hf_chips) {
        BOOL on = (b.tag == self.hf_filterStatus);
        b.backgroundColor = on ? sel : unsel;
        [b setTitleColor:ink forState:UIControlStateNormal];
    }
}

- (void)hf_orderTapChip:(UIButton *)sender {
    if (sender.tag == self.hf_filterStatus) {
        [self hf_orderReload];
        return;
    }
    self.hf_filterStatus = sender.tag;
    [self hf_orderSyncChips];
    [self hf_orderReload];
}

- (void)hf_orderReload {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pOrderList]
                              signMap:@{}
                           nonSignMap:@{ @"orderStatus": @(self.hf_filterStatus) }
                           replyClass:[HFParcelOrderListReply class]
                                   ok:^(HFParcelOrderListReply *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        self.hf_rows = reply.data.orderList ?: @[];
        [self.hf_table reloadData];
        BOOL empty = self.hf_rows.count == 0;
        self.hf_empty.hidden = !empty;
        self.hf_table.hidden = empty;
        if (empty) [self.view bringSubviewToFront:self.hf_empty];
    } fail:^(NSString * _Nullable msg, __unused NSString *code) {
        __strong typeof(weakSelf) self = weakSelf;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        self.hf_rows = @[];
        [self.hf_table reloadData];
        self.hf_empty.hidden = NO;
        self.hf_table.hidden = YES;
        [self.view bringSubviewToFront:self.hf_empty];
        [[HFOrbitHint shared] hf_orbitPulse:msg.length ? msg : @"Failed!"];
    }];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.hf_rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HFOrbitCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"c" forIndexPath:indexPath];
    if (indexPath.row < (NSInteger)self.hf_rows.count) {
        [cell hf_bind:self.hf_rows[indexPath.row]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.hf_rows.count) return;
    HFParcelOrderItem *item = self.hf_rows[indexPath.row];
    [self hf_orderOpenItem:item];
}

- (void)hf_orderOpenItem:(HFParcelOrderItem *)item {
    NSInteger st = item.orderStatus;
    // orderStatus=31 reject: prefer rejectH5; empty / invalid → original order detail.
    if (st == 31) {
        [[HFLedgerFetch shared] hf_ledgerObtain:^(HFParcelConfig * _Nullable cfg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                NSString *h5 = [cfg.dynamicParameter.rejectH5 stringByTrimmingCharactersInSet:ws] ?: @"";
                if (!h5.length) {
                    h5 = [item.rejectH5 stringByTrimmingCharactersInSet:ws] ?: @"";
                }
                HFDriftNest *web = [HFDriftNest hf_driftWithURL:h5];
                if (web) {
                    web.hidesBottomBarWhenPushed = YES;
                    [self.navigationController setNavigationBarHidden:NO animated:YES];
                    [self.navigationController pushViewController:web animated:YES];
                    return;
                }
                // Core condition unmet (rejectH5 empty) → continue original flow: order detail.
                [self hf_orderOpenDetail:item withdraw:NO];
            });
        }];
        return;
    }
    [self hf_orderOpenDetail:item withdraw:(st == 32)];
}

- (void)hf_orderOpenDetail:(HFParcelOrderItem *)item withdraw:(BOOL)withdraw {
    NSString *link = [HFVaultSeal kHrefOrderDetails];
    if (!link.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    NSMutableDictionary *ex = [NSMutableDictionary dictionary];
    if (item.orderId.length) ex[@"orderId"] = item.orderId;
    if (item.productId.length) ex[@"productId"] = item.productId;
    if (withdraw) ex[@"orderType"] = @"1";
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initH5WithURLString:link title:nil extras:ex];
    web.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:web animated:YES];
}

@end

#pragma mark - Me Tab

@interface HFDockLeafMe ()
@property (nonatomic, strong) UIImageView *hf_avatar;
@property (nonatomic, strong) UILabel *hf_nameLab;
@property (nonatomic, strong) UILabel *hf_phoneLab;
@property (nonatomic, strong) UIButton *hf_exitBtn;
@property (nonatomic, assign) NSTimeInterval hf_lastPushAt;
@end

@implementation HFDockLeafMe

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = @"";
    [self hf_buildChrome];
    [self hf_loadUser];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - UI

- (void)hf_buildChrome {
    UIColor *ink = [UIColor hf_prismInk];

    self.hf_avatar = [UIImageView new];
    self.hf_avatar.image = [UIImage imageNamed:@"logo"];
    self.hf_avatar.contentMode = UIViewContentModeScaleAspectFill;
    self.hf_avatar.backgroundColor = ink;
    self.hf_avatar.clipsToBounds = YES;
    self.hf_avatar.layer.cornerRadius = 24;
    [self.view addSubview:self.hf_avatar];

    self.hf_nameLab = [UILabel new];
    self.hf_nameLab.text = [self hf_defaultName];
    self.hf_nameLab.textColor = ink;
    self.hf_nameLab.font = [UIFont hf_latticeGlyph:16 mass:UIFontWeightRegular];
    self.hf_nameLab.numberOfLines = 0;
    self.hf_nameLab.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.hf_nameLab];

    self.hf_phoneLab = [UILabel new];
    self.hf_phoneLab.text = @"+63";
    self.hf_phoneLab.textColor = ink;
    self.hf_phoneLab.font = [UIFont hf_latticeGlyph:13 mass:UIFontWeightRegular];
    self.hf_phoneLab.textAlignment = NSTextAlignmentRight;
    [self.hf_phoneLab setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.hf_phoneLab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.view addSubview:self.hf_phoneLab];

    NSArray *items = @[
        @{ @"title": @"Repayment Instructions", @"icon": @"one_icon_Repayment plan", @"tag": @0 },
        @{ @"title": @"About", @"icon": @"one_icon_About", @"tag": @1 },
        @{ @"title": @"Privacy policy", @"icon": @"one_icon_me", @"tag": @2 },
        @{ @"title": @"Terms of the loan", @"icon": @"one_icon_order", @"tag": @3 },
    ];

    UIView *grid = [UIView new];
    [self.view addSubview:grid];

    NSMutableArray<UIButton *> *cells = [NSMutableArray array];
    for (NSDictionary *it in items) {
        UIButton *cell = [self hf_gridCell:it[@"title"] icon:it[@"icon"] tag:[it[@"tag"] integerValue]];
        [grid addSubview:cell];
        [cells addObject:cell];
    }

    self.hf_exitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hf_exitBtn.backgroundColor = UIColor.whiteColor;
    self.hf_exitBtn.layer.cornerRadius = 28;
    [self.hf_exitBtn setTitle:@"Sign out" forState:UIControlStateNormal];
    [self.hf_exitBtn setTitleColor:[UIColor hf_prismTheme] forState:UIControlStateNormal];
    self.hf_exitBtn.titleLabel.font = [UIFont hf_latticeGlyph:17 mass:UIFontWeightRegular];
    [self.hf_exitBtn addTarget:self action:@selector(hf_tapExit) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.hf_exitBtn];

    [self.hf_avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.leading.equalTo(self.view).offset(24);
        make.width.height.mas_equalTo(48);
    }];
    [self.hf_phoneLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.hf_avatar);
        make.trailing.equalTo(self.view).offset(-24);
    }];
    // Wrap allowed; whole label block stays vertically centered with avatar.
    [self.hf_nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.hf_avatar);
        make.leading.equalTo(self.hf_avatar.mas_trailing).offset(12);
        make.trailing.lessThanOrEqualTo(self.hf_phoneLab.mas_leading).offset(-8);
    }];

    [grid mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.greaterThanOrEqualTo(self.hf_avatar.mas_bottom).offset(28);
        make.top.greaterThanOrEqualTo(self.hf_nameLab.mas_bottom).offset(28);
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
    }];

    UIButton *c0 = cells[0], *c1 = cells[1], *c2 = cells[2], *c3 = cells[3];
    [c0 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(grid);
        make.height.mas_equalTo(110);
    }];
    [c1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.trailing.equalTo(grid);
        make.leading.equalTo(c0.mas_trailing).offset(12);
        make.width.height.equalTo(c0);
    }];
    [c2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(c0.mas_bottom).offset(12);
        make.leading.bottom.equalTo(grid);
        make.width.height.equalTo(c0);
    }];
    [c3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(c2);
        make.trailing.equalTo(grid);
        make.leading.equalTo(c2.mas_trailing).offset(12);
        make.width.height.equalTo(c0);
    }];

    [self.hf_exitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(24);
        make.trailing.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(56);
    }];
}

- (UIButton *)hf_gridCell:(NSString *)title icon:(NSString *)icon tag:(NSInteger)tag {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.backgroundColor = UIColor.whiteColor;
    b.layer.cornerRadius = 16;
    b.tag = tag;
    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    b.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;

    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:icon]];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.userInteractionEnabled = NO;
    iv.tag = 101;
    [b addSubview:iv];

    UILabel *lab = [UILabel new];
    lab.text = title;
    lab.textColor = [UIColor hf_prismInk];
    lab.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    lab.numberOfLines = 2;
    lab.userInteractionEnabled = NO;
    lab.tag = 102;
    [b addSubview:lab];

    [iv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(b).offset(18);
        make.leading.equalTo(b).offset(16);
        make.width.height.mas_equalTo(28);
    }];
    [lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(iv.mas_bottom).offset(12);
        make.leading.equalTo(b).offset(16);
        make.trailing.equalTo(b).offset(-12);
    }];

    [b addTarget:self action:@selector(hf_tapCell:) forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (NSString *)hf_defaultName {
    NSString *n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!n.length) n = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return n.length ? n : @"App";
}

#pragma mark - Data

- (void)hf_loadUser {
    [[HFOrbitHint shared] hf_orbitSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pUserInfo]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelUserReply class]
                                   ok:^(HFParcelUserReply *reply) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [[HFOrbitHint shared] hf_orbitHaltSpin];
        HFParcelUser *u = reply.data;
        if (u.name.length > 0) {
            self.hf_nameLab.text = u.name;
        }
        if (u.phone.length > 0) {
            self.hf_phoneLab.text = [NSString stringWithFormat:@"+63%@", u.phone];
            [HFQuillVault hf_quillPersistPhone:u.phone];
        } else {
            self.hf_phoneLab.text = @"+63";
        }
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        [[HFOrbitHint shared] hf_orbitHaltSpin];
    }];
}

#pragma mark - Actions

- (BOOL)hf_canPush {
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - self.hf_lastPushAt < kHFMePushGap) return NO;
    self.hf_lastPushAt = now;
    return YES;
}

- (void)hf_tapCell:(UIButton *)sender {
    if (![self hf_canPush]) return;
    switch (sender.tag) {
        case 0: {
            HFRelayNote *vc = [HFRelayNote new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 1: {
            HFAmberNest *vc = [HFAmberNest new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 2:
            [self hf_openStaticWeb:[HFVaultSeal kHrefPrivacy] title:@"Privacy policy"];
            break;
        case 3:
            [self hf_openStaticWeb:[HFVaultSeal kHrefLoanTerms] title:@"Terms of the loan"];
            break;
        default:
            break;
    }
}

- (void)hf_openStaticWeb:(NSString *)href title:(NSString *)title {
    if (!href.length) {
        [[HFOrbitHint shared] hf_orbitPulse:@"Not available"];
        return;
    }
    HFPaneBrowse *web = [[HFPaneBrowse alloc] initWithURLString:href title:title];
    web.hidesBottomBarWhenPushed = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:web animated:YES];
}

- (void)hf_tapExit {
    __weak typeof(self) weakSelf = self;
    [[HFCurtainBox shared] hf_curtainAlert:@"Sign out"
                                   message:@"Are you sure you want to sign out?"
                              confirmTitle:@"Confirm"
                               cancelTitle:@"Cancel"
                                      tier:HFCurtainTierMid
                                   confirm:^{
        [HFQuillVault hf_quillErase];
        [[HFOrbitHint shared] hf_orbitPulse:@"Sign out successfully"];
        [weakSelf hf_goGate];
    } cancel:nil];
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
