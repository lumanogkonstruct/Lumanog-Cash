#import "HFFloatOrb.h"

@implementation HFFloatOrb

+ (instancetype)shared {
    static HFFloatOrb *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFFloatOrb new];
    });
    return ins;
}

- (void)hf_orbShow {
    NSLog(@"[HFFloatOrb] show (stub)");
}

- (void)hf_orbHide {
    NSLog(@"[HFFloatOrb] hide (stub)");
}

- (void)hf_orbSetURL:(NSString *)url {
    NSLog(@"[HFFloatOrb] setURL=%@", url ?: @"");
}

@end
