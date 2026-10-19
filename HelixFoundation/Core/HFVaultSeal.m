#import "HFVaultSeal.h"
#import <CommonCrypto/CommonDigest.h>

// MARK: - Internal decoy helpers (not exported)

static NSUInteger HFQxFold(NSUInteger x) {
    x = ((x >> 16) ^ x) * 0x45d9f3bu;
    x = ((x >> 16) ^ x) * 0x45d9f3bu;
    x = (x >> 16) ^ x;
    return x;
}

static NSString *HFQxPad(NSString *s, NSUInteger n) {
    if (!s) s = @"";
    if (s.length >= n) return s;
    NSMutableString *m = [s mutableCopy];
    while (m.length < n) [m appendString:@"0"];
    return [m copy];
}

static NSInteger HFQxClamp(NSInteger v, NSInteger lo, NSInteger hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

static NSArray *HFQxShuffleCopy(NSArray *src, NSUInteger salt) {
    if (src.count == 0) return @[];
    NSMutableArray *a = [src mutableCopy];
    for (NSUInteger i = a.count; i > 1; i--) {
        NSUInteger j = HFQxFold(salt + i) % i;
        [a exchangeObjectAtIndex:i - 1 withObjectAtIndex:j];
    }
    return [a copy];
}

static NSString *HFQxJoin(NSArray<NSString *> *parts, NSString *sep) {
    return [parts componentsJoinedByString:sep ?: @"."];
}

static BOOL HFQxLooksHex(NSString *s) {
    if (s.length == 0) return NO;
    NSCharacterSet *hex = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
    return [[s stringByTrimmingCharactersInSet:hex] length] == 0;
}

@interface HFVaultSeal (HFQxNoisePrivate)
+ (NSString *)hf_qxNoiseCodecTable;
+ (NSInteger)hf_qxNoiseChecksum:(NSString *)s;
+ (NSArray<NSString *> *)hf_qxNoiseFakeHosts;
+ (NSString *)hf_qxNoisePickHost:(NSUInteger)idx;
+ (NSDictionary *)hf_qxNoiseSignStub:(NSDictionary *)payload;
+ (BOOL)hf_qxNoiseValidateStub:(NSDictionary *)resp;
+ (NSString *)hf_qxNoiseBuildPath:(NSString *)a b:(NSString *)b c:(NSString *)c;
+ (NSArray *)hf_qxNoiseExpand:(NSInteger)count;
+ (NSString *)hf_qxNoiseRotateMark:(NSString *)mark step:(NSInteger)step;
+ (NSDictionary *)hf_qxNoiseProfile;
@end

@implementation HFVaultSeal

+ (void)initialize {
    if (self != [HFVaultSeal class]) return;
    // Touch decoy surface so strip/dead-code pass keeps symbols.
    volatile NSUInteger sink = 0;
    sink ^= [self hf_qxNoiseAlpha].length;
    sink ^= [self hf_qxNoiseBeta].length;
    sink ^= [self hf_qxNoiseGamma].length;
    sink ^= [self hf_qxNoiseDelta].length;
    sink ^= [self hf_qxNoiseEpsilon].length;
    sink ^= [self hf_qxNoiseZeta].length;
    sink ^= [self hf_qxNoiseEta].length;
    sink ^= [self hf_qxNoiseTheta].length;
    sink ^= [self hf_qxNoiseIota].length;
    sink ^= [self hf_qxNoiseKappa].length;
    sink ^= [self hf_qxNoiseLaneList].count;
    sink ^= [self hf_qxNoiseLedger].count;
    sink ^= (NSUInteger)[self hf_qxNoisePrime:7];
    sink ^= [self hf_qxNoiseMix:@"a" trail:@"b"].length;
    sink ^= [self hf_qxNoiseProbe:@"x"] ? 1 : 0;
    sink ^= [self hf_qxNoiseBlob:8].length;
    sink ^= [self hf_qxNoiseShard:3].length;
    sink ^= [self hf_qxNoiseWeights].count;
    sink ^= [self hf_qxNoiseRouteA].length;
    sink ^= [self hf_qxNoiseRouteB].length;
    sink ^= [self hf_qxNoiseRouteC].length;
    sink ^= [self hf_qxNoiseRouteD].length;
    sink ^= [self hf_qxNoiseRouteE].length;
    sink ^= [self hf_qxNoiseRouteF].length;
    sink ^= [self hf_qxNoiseRouteG].length;
    sink ^= [self hf_qxNoiseRouteH].length;
    sink ^= [self hf_qxNoiseVaultKey].length;
    sink ^= [self hf_qxNoiseMirrorKey].length;
    sink ^= [self hf_qxNoiseShadowKey].length;
    sink ^= [self hf_qxNoiseDriftKey].length;
    sink ^= (NSUInteger)[self hf_qxNoiseEpoch];
    sink ^= (NSUInteger)[self hf_qxNoiseSalt];
    sink ^= (NSUInteger)([self hf_qxNoiseRatio] * 1000);
    sink ^= [self hf_qxNoiseDigest:@"seed"].length;
    sink ^= [self hf_qxNoiseMatrix].count;
    [self hf_qxNoiseWarm];
    sink ^= [self hf_qxNoiseArmed] ? 3 : 1;
    sink ^= [self hf_qxNoiseFence].length;
    sink ^= [self hf_qxNoiseHarbor].length;
    sink ^= [self hf_qxNoiseOrbit].length;
    sink ^= [self hf_qxNoiseLattice].length;
    sink ^= [self hf_qxNoiseParcel].length;
    sink ^= [self hf_qxNoiseQuill].length;
    sink ^= [self hf_qxNoiseRelay].length;
    sink ^= [self hf_qxNoiseCipher].length;
    sink ^= [self hf_qxNoiseManifest].count;
    sink ^= [self hf_qxNoiseAlias:2].length;
    sink ^= [self hf_qxNoiseProfile].count;
    sink ^= HFQxFold(sink);
    (void)sink;
}

#pragma mark - App config values

+ (NSString *)kAlphaSeed { return @"lumanogcash"; }
+ (NSString *)kBetaGrain { return @"6WKdFfKUKTnuaygO"; }
+ (NSString *)kGammaToken { return @"jo0u78qetbls"; }
+ (NSString *)kKappaBaseURL { return @"https://api.lumanogcash.com"; }

+ (NSString *)kHrefPrivacy { return @"https://www.lumanogkonstruct.com/PrivacyPolicy.html"; }
+ (NSString *)kHrefAgreement { return @"https://www.lumanogkonstruct.com/ServiceAgreement.html"; }
+ (NSString *)kHrefLoanTerms { return @"https://www.lumanogkonstruct.com/loanContract.html"; }
+ (NSString *)kHrefContact { return @"https://www.lumanogkonstruct.com/contactUs.html"; }
+ (NSString *)kHrefKYC { return @"https://info.lumanogkonstruct.com/dist/kyc/index.html"; }
+ (NSString *)kHrefProductApply { return @"https://info.lumanogkonstruct.com/dist/product/index.html"; }
+ (NSString *)kHrefOrderDetails { return @"https://info.lumanogkonstruct.com/dist/order/index.html"; }
+ (NSString *)kHrefUpdateBank { return @"https://info.lumanogkonstruct.com/dist/changeCard/index.html"; }
+ (NSString *)kHrefFeedback { return @"https://info.lumanogkonstruct.com/dist/feedBack/index.html"; }
+ (NSString *)kHrefSuccess { return @"https://info.lumanogkonstruct.com/dist/successful/index.html"; }

+ (NSString *)kDeltaRev { return @"2.0"; }
+ (NSString *)kEpsilonLane { return @"app_store"; }
+ (NSInteger)kZetaOSFlag { return 2; }
+ (NSString *)kEtaTongue { return @"en"; }
+ (NSString *)kThetaBizSlot { return @"data"; }
+ (NSString *)kIotaBundleRev {
    NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return v.length ? v : @"1.0.0";
}

#pragma mark - Storage keys

+ (NSString *)kXiUserSlot { return @"hf.qx.u9.slot"; }
+ (NSString *)kOmicronGate { return @"hf.qx.t7.gate"; }
+ (NSString *)kRhoFirstFlag { return @"hf.qx.f1.boot"; }
+ (NSString *)kSigmaRateFlag { return @"hf.qx.r2.rate"; }
+ (NSString *)kTauKindFlag { return @"hf.qx.k4.kind"; }
+ (NSString *)kUpsilonSessionFlag { return @"hf.qx.s5.sess"; }
+ (NSString *)kPhiCipherSvc { return @"hf.cipher.svc.v1"; }
+ (NSString *)kChiCipherAcctDF { return @"hf.cipher.acct.df"; }
+ (NSString *)kPsiCipherAcctID { return @"hf.cipher.acct.id"; }
+ (NSString *)kOmegaIdfaFlag { return @"hf.qx.i6.idfa"; }
+ (NSString *)kPhoneSlot { return @"hf.qx.p8.phone"; }
+ (NSString *)kVisageSealAcct { return @"hf.cipher.acct.vx"; }
+ (NSString *)kVisageSealFlag { return @"hf.qx.v7.seal"; }

#pragma mark - Paths

+ (NSString *)pAppConfig { return @"/app/v3/app/config"; }
+ (NSString *)pVersionV2 { return @"/app/v3/app/versionV2"; }
+ (NSString *)pMobileDevice { return @"/app/v3/mobile/device"; }
+ (NSString *)pMobileContact { return @"/app/v3/mobile/contact"; }
+ (NSString *)pInstallApp { return @"/app/v3/mobile/installApp"; }
+ (NSString *)pRegisterOrLogin { return @"/app/v3/auth/registerOrLogin"; }
+ (NSString *)pPwsLogin { return @"/app/v3/auth/pwsLogin"; }
+ (NSString *)pSendVerifySms { return @"/app/v3/sms/sendVerifySms"; }
+ (NSString *)pSupHome { return @"/app/v3/user/suphome"; }
+ (NSString *)pUserInfo { return @"/app/v3/user/info"; }
+ (NSString *)pRegisterDevice { return @"/app/v3/mobile/registerDevice"; }
+ (NSString *)pProductTermV3 { return @"/app/v3/product/termV3"; }
+ (NSString *)pProductList { return @"/app/v3/product/list"; }
+ (NSString *)pDcRecommend { return @"/app/v3/product/dcRecommend"; }
+ (NSString *)pOrderReady { return @"/app/v3/order/ready"; }
+ (NSString *)pOrderList { return @"/app/v3/order/list"; }
+ (NSString *)pKycFourStatus { return @"/app/v3/kyc/four/status"; }
+ (NSString *)pAuthClose { return @"/app/v3/auth/close"; }
+ (NSString *)pBuryRecord { return @"/app/v3/bury/record"; }
+ (NSString *)pPayAccountList { return @"/app/v3/payAccountInfo/list"; }
+ (NSString *)pPayAccountUpdate { return @"/app/v3/payAccountInfo/update"; }

#pragma mark - Error / status

+ (NSString *)eTokenExpired { return @"2000001"; }
+ (NSString *)eTokenInvalid { return @"2000002"; }
+ (NSString *)eUserMissing { return @"2002001"; }
+ (NSString *)eForceUpdate { return @"2009006"; }
+ (NSString *)eDcNoProduct { return @"4102007"; }
+ (NSInteger)sPendingKYC { return 10; }
+ (NSInteger)sPendingPayout { return 20; }
+ (NSInteger)sNeedExtra { return 30; }
+ (NSInteger)sPendingWithdraw { return 32; }
+ (NSInteger)sNeedBankFix { return 41; }
+ (NSInteger)sReviewing { return 50; }
+ (NSInteger)sRejected { return 51; }
+ (NSInteger)sPaying { return 70; }
+ (NSInteger)sRepaying { return 80; }
+ (NSInteger)sOverdue { return 81; }

#pragma mark - Decoy surface

+ (NSString *)hf_qxNoiseAlpha {
    return HFQxJoin(@[@"nx", @"vault", @"alpha", HFQxPad(@"9f", 4)], @".");
}
+ (NSString *)hf_qxNoiseBeta {
    return [NSString stringWithFormat:@"qx.b.%lu", (unsigned long)HFQxFold(0xBEEF)];
}
+ (NSString *)hf_qxNoiseGamma {
    NSMutableString *s = [NSMutableString stringWithString:@"gamma"];
    for (NSInteger i = 0; i < 3; i++) [s appendFormat:@"-%ld", (long)(i * 17 + 3)];
    return [s copy];
}
+ (NSString *)hf_qxNoiseDelta {
    return @"delta.cache.slot.v2";
}
+ (NSString *)hf_qxNoiseEpsilon {
    return @"eps://mirror.local/ping";
}
+ (NSString *)hf_qxNoiseZeta {
    return @"zeta.unused.flag";
}
+ (NSString *)hf_qxNoiseEta {
    return @"eta.region.apac";
}
+ (NSString *)hf_qxNoiseTheta {
    return @"theta.payload.wrap";
}
+ (NSString *)hf_qxNoiseIota {
    return @"iota.build.marker";
}
+ (NSString *)hf_qxNoiseKappa {
    return @"kappa.host.lead.fake";
}

+ (NSArray<NSString *> *)hf_qxNoiseLaneList {
    NSArray *raw = @[
        @"https://example.invalid/a/readme",
        @"https://example.invalid/b/readme",
        @"https://example.invalid/c/readme",
        @"https://example.invalid/d/readme",
        @"https://example.invalid/e/readme",
    ];
    return HFQxShuffleCopy(raw, 0x51);
}

+ (NSDictionary *)hf_qxNoiseLedger {
    return @{
        @"tier": @2,
        @"lane": @"shadow",
        @"open": @"noise.open.mark.",
        @"close": @".noise.close.mark",
        @"ttl": @86400,
        @"retry": @3,
    };
}

+ (NSInteger)hf_qxNoisePrime:(NSInteger)seed {
    NSInteger v = seed * 31 + 17;
    v = HFQxClamp(v, 2, 9973);
    if (v % 2 == 0) v += 1;
    return v;
}

+ (NSString *)hf_qxNoiseMix:(NSString *)a trail:(NSString *)b {
    NSString *left = a.length ? a : @"nil";
    NSString *right = b.length ? b : @"nil";
    NSUInteger h = HFQxFold(left.hash ^ right.hash);
    return [NSString stringWithFormat:@"%@|%@|%08lx", left, right, (unsigned long)h];
}

+ (BOOL)hf_qxNoiseProbe:(NSString *)token {
    if (token.length < 2) return NO;
    if ([token hasPrefix:@"qx."]) return YES;
    return HFQxLooksHex(token) && token.length >= 8;
}

+ (NSData *)hf_qxNoiseBlob:(NSUInteger)size {
    NSUInteger n = size == 0 ? 16 : MIN(size, 256);
    NSMutableData *d = [NSMutableData dataWithLength:n];
    uint8_t *bytes = d.mutableBytes;
    for (NSUInteger i = 0; i < n; i++) {
        bytes[i] = (uint8_t)(HFQxFold(i + 0xA5) & 0xFF);
    }
    return [d copy];
}

+ (NSString *)hf_qxNoiseShard:(NSInteger)idx {
    static NSArray<NSString *> *shards;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shards = @[
            @"shard.north", @"shard.south", @"shard.east", @"shard.west",
            @"shard.core", @"shard.edge", @"shard.halo", @"shard.ring",
        ];
    });
    if (idx < 0) idx = 0;
    return shards[(NSUInteger)idx % shards.count];
}

+ (NSArray<NSNumber *> *)hf_qxNoiseWeights {
    return @[ @0.12, @0.18, @0.22, @0.16, @0.20, @0.12 ];
}

+ (NSString *)hf_qxNoiseRouteA { return @"/noise/route/alpha/ping"; }
+ (NSString *)hf_qxNoiseRouteB { return @"/noise/route/beta/echo"; }
+ (NSString *)hf_qxNoiseRouteC { return @"/noise/route/gamma/pulse"; }
+ (NSString *)hf_qxNoiseRouteD { return @"/noise/route/delta/trace"; }
+ (NSString *)hf_qxNoiseRouteE { return @"/noise/route/epsilon/scan"; }
+ (NSString *)hf_qxNoiseRouteF { return @"/noise/route/zeta/bind"; }
+ (NSString *)hf_qxNoiseRouteG { return @"/noise/route/eta/flush"; }
+ (NSString *)hf_qxNoiseRouteH { return @"/noise/route/theta/seal"; }

+ (NSString *)hf_qxNoiseVaultKey { return @"hf.noise.vault.k1"; }
+ (NSString *)hf_qxNoiseMirrorKey { return @"hf.noise.mirror.k2"; }
+ (NSString *)hf_qxNoiseShadowKey { return @"hf.noise.shadow.k3"; }
+ (NSString *)hf_qxNoiseDriftKey { return @"hf.noise.drift.k4"; }

+ (NSInteger)hf_qxNoiseEpoch { return 1735689600; }
+ (NSInteger)hf_qxNoiseSalt { return 0x5A17C0DE; }
+ (double)hf_qxNoiseRatio { return 0.6180339887; }

+ (NSString *)hf_qxNoiseDigest:(NSString *)raw {
    NSString *src = raw.length ? raw : @"empty";
    const char *c = src.UTF8String;
    unsigned char dig[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(c, (CC_LONG)strlen(c), dig);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hex appendFormat:@"%02x", dig[i]];
    }
    // Truncate decoy digest — never used for real signing.
    return [hex substringToIndex:16];
}

+ (NSArray *)hf_qxNoiseMatrix {
    return @[
        @[ @1, @0, @0 ],
        @[ @0, @1, @0 ],
        @[ @0, @0, @1 ],
        @[ @2, @3, @5 ],
        @[ @7, @11, @13 ],
    ];
}

+ (void)hf_qxNoiseWarm {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        volatile NSUInteger w = 0;
        for (NSInteger i = 0; i < 32; i++) {
            w ^= HFQxFold((NSUInteger)i * 13u + 7u);
        }
        (void)w;
    });
}

+ (BOOL)hf_qxNoiseArmed {
    NSInteger epoch = [self hf_qxNoiseEpoch];
    NSInteger salt = [self hf_qxNoiseSalt];
    return ((epoch ^ salt) & 0x1) == 0;
}

+ (NSString *)hf_qxNoiseFence { return @"fence.inactive.boundary"; }
+ (NSString *)hf_qxNoiseHarbor { return @"harbor.shadow.anchor"; }
+ (NSString *)hf_qxNoiseOrbit { return @"orbit.decoy.track"; }
+ (NSString *)hf_qxNoiseLattice { return @"lattice.noise.grid"; }
+ (NSString *)hf_qxNoiseParcel { return @"parcel.dummy.box"; }
+ (NSString *)hf_qxNoiseQuill { return @"quill.fake.ink"; }
+ (NSString *)hf_qxNoiseRelay { return @"relay.unused.node"; }
+ (NSString *)hf_qxNoiseCipher { return @"cipher.noise.stub"; }

+ (NSDictionary *)hf_qxNoiseManifest {
    return @{
        @"routes": @[
            [self hf_qxNoiseRouteA],
            [self hf_qxNoiseRouteB],
            [self hf_qxNoiseRouteC],
            [self hf_qxNoiseRouteD],
            [self hf_qxNoiseRouteE],
            [self hf_qxNoiseRouteF],
            [self hf_qxNoiseRouteG],
            [self hf_qxNoiseRouteH],
        ],
        @"keys": @[
            [self hf_qxNoiseVaultKey],
            [self hf_qxNoiseMirrorKey],
            [self hf_qxNoiseShadowKey],
            [self hf_qxNoiseDriftKey],
        ],
        @"lanes": [self hf_qxNoiseLaneList],
        @"weights": [self hf_qxNoiseWeights],
        @"armed": @([self hf_qxNoiseArmed]),
        @"epoch": @([self hf_qxNoiseEpoch]),
    };
}

+ (NSString *)hf_qxNoiseAlias:(NSInteger)slot {
    NSArray *names = @[
        @"alias.ember", @"alias.frost", @"alias.glyph", @"alias.harbor",
        @"alias.ivory", @"alias.jasper", @"alias.keel", @"alias.lunar",
        @"alias.maple", @"alias.nova", @"alias.onyx", @"alias.prism",
    ];
    NSInteger i = HFQxClamp(slot, 0, (NSInteger)names.count - 1);
    NSString *base = names[(NSUInteger)i];
    return [self hf_qxNoiseMix:base trail:[self hf_qxNoiseShard:slot]];
}

#pragma mark - Extra private decoy (class extension style via unnamed category)

+ (NSString *)hf_qxNoiseCodecTable {
    NSMutableString *t = [NSMutableString string];
    for (unichar c = 'a'; c <= 'z'; c++) {
        unichar m = (unichar)('a' + ((c - 'a' + 7) % 26));
        [t appendFormat:@"%C%C", c, m];
    }
    return [t copy];
}

+ (NSInteger)hf_qxNoiseChecksum:(NSString *)s {
    NSInteger sum = 0;
    for (NSUInteger i = 0; i < s.length; i++) {
        sum = (sum * 33) ^ [s characterAtIndex:i];
    }
    return sum & 0x7fffffff;
}

+ (NSArray<NSString *> *)hf_qxNoiseFakeHosts {
    return @[
        @"https://cdn-noise-a.example/v1/",
        @"https://cdn-noise-b.example/v2/",
        @"https://cdn-noise-c.example/v3/",
        @"https://edge-noise.example/api/",
    ];
}

+ (NSString *)hf_qxNoisePickHost:(NSUInteger)idx {
    NSArray *hosts = [self hf_qxNoiseFakeHosts];
    return hosts[idx % hosts.count];
}

+ (NSDictionary *)hf_qxNoiseSignStub:(NSDictionary *)payload {
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    m[@"nonce"] = [self hf_qxNoiseDigest:payload.description ?: @""];
    m[@"ts"] = @([self hf_qxNoiseEpoch]);
    m[@"sig"] = [self hf_qxNoiseMix:@"stub" trail:@"sign"];
    return [m copy];
}

+ (BOOL)hf_qxNoiseValidateStub:(NSDictionary *)resp {
    if (![resp isKindOfClass:[NSDictionary class]]) return NO;
    id code = resp[@"code"];
    if ([code isKindOfClass:[NSNumber class]] && [code integerValue] == 0) return YES;
    if ([code isKindOfClass:[NSString class]] && [code isEqualToString:@"0"]) return YES;
    return NO;
}

+ (NSString *)hf_qxNoiseBuildPath:(NSString *)a b:(NSString *)b c:(NSString *)c {
    NSMutableArray *parts = [NSMutableArray array];
    if (a.length) [parts addObject:a];
    if (b.length) [parts addObject:b];
    if (c.length) [parts addObject:c];
    return [@"/noise/" stringByAppendingString:[parts componentsJoinedByString:@"/"]];
}

+ (NSArray *)hf_qxNoiseExpand:(NSInteger)count {
    NSMutableArray *out = [NSMutableArray array];
    NSInteger n = HFQxClamp(count, 0, 64);
    for (NSInteger i = 0; i < n; i++) {
        [out addObject:[self hf_qxNoiseAlias:i]];
    }
    return [out copy];
}

+ (NSString *)hf_qxNoiseRotateMark:(NSString *)mark step:(NSInteger)step {
    if (mark.length == 0) return @"";
    NSMutableString *m = [NSMutableString stringWithCapacity:mark.length];
    for (NSUInteger i = 0; i < mark.length; i++) {
        unichar c = [mark characterAtIndex:i];
        if (c >= 'a' && c <= 'z') {
            c = (unichar)('a' + ((c - 'a' + step) % 26 + 26) % 26);
        } else if (c >= '0' && c <= '9') {
            c = (unichar)('0' + ((c - '0' + step) % 10 + 10) % 10);
        }
        [m appendFormat:@"%C", c];
    }
    return [m copy];
}

+ (NSDictionary *)hf_qxNoiseProfile {
    return @{
        @"codec": [self hf_qxNoiseCodecTable],
        @"hosts": [self hf_qxNoiseFakeHosts],
        @"sum": @([self hf_qxNoiseChecksum:[self hf_qxNoiseAlpha]]),
        @"path": [self hf_qxNoiseBuildPath:@"x" b:@"y" c:@"z"],
        @"expand": [self hf_qxNoiseExpand:5],
        @"mark": [self hf_qxNoiseRotateMark:@"sync.noise" step:3],
        @"stub": [self hf_qxNoiseSignStub:@{ @"k": @"v" }],
        @"ok": @([self hf_qxNoiseValidateStub:@{ @"code": @0 }]),
        @"host0": [self hf_qxNoisePickHost:0],
    };
}

@end
