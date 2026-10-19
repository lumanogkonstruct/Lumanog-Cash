#import "HFMintForge.h"
#import "HFLatticeKit.h"
#import <Masonry/Masonry.h>

@implementation HFMintForge

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hf_navTitle = self.hf_forgeAddMode ? @"Add Bank Account" : @"Change Bank Account";
    self.title = self.hf_navTitle;

    UILabel *hint = [UILabel new];
    hint.text = @"Coming soon";
    hint.textColor = [UIColor hf_prismHex:@"#8A8178"];
    hint.font = [UIFont hf_latticeGlyph:14 mass:UIFontWeightRegular];
    hint.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:hint];
    [hint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.leading.greaterThanOrEqualTo(self.view).offset(24);
        make.trailing.lessThanOrEqualTo(self.view).offset(-24);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

@end
