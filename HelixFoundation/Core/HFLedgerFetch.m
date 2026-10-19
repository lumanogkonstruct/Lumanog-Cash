#import "HFLedgerFetch.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFParcelModels.h"

@interface HFLedgerFetch ()
@property (nonatomic, strong, nullable) HFParcelConfig *cache;
@property (nonatomic, assign) BOOL forcing;
@property (nonatomic, assign) BOOL obtaining;
@property (nonatomic, strong) NSMutableArray *forceWait;
@property (nonatomic, strong) NSMutableArray *obtainWait;
@end

@implementation HFLedgerFetch

+ (instancetype)shared {
    static HFLedgerFetch *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFLedgerFetch new];
        ins.forceWait = [NSMutableArray array];
        ins.obtainWait = [NSMutableArray array];
    });
    return ins;
}

- (HFParcelConfig *)hf_ledgerCache {
    return self.cache;
}

- (void)hf_ledgerWipe {
    self.cache = nil;
}

- (void)hf_ledgerForce:(void (^)(HFParcelConfig * _Nullable))done {
    if (done) [self.forceWait addObject:[done copy]];
    if (self.forcing) return;
    self.forcing = YES;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pAppConfig]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelConfigReply class]
                                   ok:^(HFParcelConfigReply *reply) {
        if (reply.data) self.cache = reply.data;
        NSArray *waits = [self.forceWait copy];
        [self.forceWait removeAllObjects];
        self.forcing = NO;
        for (void (^b)(HFParcelConfig *) in waits) {
            b(self.cache);
        }
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        NSArray *waits = [self.forceWait copy];
        [self.forceWait removeAllObjects];
        self.forcing = NO;
        for (void (^b)(HFParcelConfig *) in waits) {
            b(self.cache);
        }
    }];
}

- (void)hf_ledgerObtain:(void (^)(HFParcelConfig * _Nullable))done {
    if (self.cache) {
        if (done) done(self.cache);
        return;
    }
    if (done) [self.obtainWait addObject:[done copy]];
    if (self.obtaining) return;
    self.obtaining = YES;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pAppConfig]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelConfigReply class]
                                   ok:^(HFParcelConfigReply *reply) {
        if (reply.data) self.cache = reply.data;
        NSArray *waits = [self.obtainWait copy];
        [self.obtainWait removeAllObjects];
        self.obtaining = NO;
        for (void (^b)(HFParcelConfig *) in waits) {
            b(self.cache);
        }
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        NSArray *waits = [self.obtainWait copy];
        [self.obtainWait removeAllObjects];
        self.obtaining = NO;
        for (void (^b)(HFParcelConfig *) in waits) {
            b(nil);
        }
    }];
}

@end
