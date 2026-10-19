#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFCipherTag.h"
#import "HFProbeAtlas.h"
#import "HFQuillVault.h"
#import "HFRealmGate.h"
#import "HFOrbitHint.h"
#import "HFParcelBase.h"
#import "HFParcelModels.h"
#import "HFCurtainBox.h"
#import "SceneDelegate.h"
#import <AFNetworking/AFNetworking.h>
#import <CommonCrypto/CommonDigest.h>
#import <YYModel/YYModel.h>
#import <Network/Network.h>

@interface HFNexusPipe ()
@property (nonatomic, strong) AFHTTPSessionManager *mgr;
@property (nonatomic, assign) BOOL forceShowing;
@property (nonatomic, strong) nw_path_monitor_t hf_pathMon;
@property (nonatomic, assign) BOOL hf_pathKnown;
@property (nonatomic, assign) BOOL hf_online;
@property (nonatomic, copy, nullable) void (^hf_pendingOnline)(BOOL ok);
@end

@implementation HFNexusPipe

+ (instancetype)shared {
    static HFNexusPipe *ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ins = [HFNexusPipe new];
        [ins hf_setup];
    });
    return ins;
}

- (void)hf_setup {
    self.mgr = [AFHTTPSessionManager manager];
    self.mgr.requestSerializer = [AFJSONRequestSerializer serializer];
    self.mgr.responseSerializer = [AFJSONResponseSerializer serializer];
    self.mgr.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", @"text/html", nil];
    self.mgr.requestSerializer.timeoutInterval = 30;
    [self hf_startPathMonitor];
}

- (void)hf_startPathMonitor {
    if (self.hf_pathMon) return;
    self.hf_pathMon = nw_path_monitor_create();
    nw_path_monitor_set_queue(self.hf_pathMon, dispatch_get_main_queue());
    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(self.hf_pathMon, ^(nw_path_t path) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        BOOL on = (nw_path_get_status(path) == nw_path_status_satisfied);
        self.hf_pathKnown = YES;
        self.hf_online = on;
        NSLog(@"[HFNexusPipe][Net] online=%d", on ? 1 : 0);
        if (on && self.hf_pendingOnline) {
            void (^cb)(BOOL) = self.hf_pendingOnline;
            self.hf_pendingOnline = nil;
            cb(YES);
        }
    });
    nw_path_monitor_start(self.hf_pathMon);
}

/// Wait until path is satisfied (or already known online). No offline toast.
- (void)hf_pipeWhenOnline:(void (^)(BOOL ok))done {
    if (!done) return;
    [self hf_startPathMonitor];
    if (self.hf_pathKnown && self.hf_online) {
        done(YES);
        return;
    }
    if (self.hf_pathKnown && !self.hf_online) {
        self.hf_pendingOnline = done;
        return;
    }
    // First path update not yet received — wait briefly.
    self.hf_pendingOnline = done;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.hf_pendingOnline) return;
        if (self.hf_online) {
            void (^cb)(BOOL) = self.hf_pendingOnline;
            self.hf_pendingOnline = nil;
            cb(YES);
        }
        // Still offline: keep pendingOnline until path becomes satisfied.
    });
}

- (BOOL)hf_pipeGuardOnlineOrFail:(HFNexusFail)fail {
    if (self.hf_pathKnown && self.hf_online) return YES;
    if (!self.hf_pathKnown) {
        // Unknown yet — allow request (avoid blocking forever on first ms).
        return YES;
    }
    // Offline: fail silently (no toast).
    dispatch_async(dispatch_get_main_queue(), ^{
        if (fail) fail(nil, nil);
    });
    return NO;
}

- (void)hf_logChunk:(NSString *)tag body:(NSString *)body {
    NSUInteger max = 900;
    if (body.length <= max) {
        NSLog(@"[HFNexusPipe][%@] %@", tag, body);
        return;
    }
    NSUInteger parts = (body.length + max - 1) / max;
    for (NSUInteger i = 0; i < parts; i++) {
        NSRange r = NSMakeRange(i * max, MIN(max, body.length - i * max));
        NSLog(@"[HFNexusPipe][%@] (%lu/%lu) %@", tag, (unsigned long)(i + 1), (unsigned long)parts, [body substringWithRange:r]);
    }
}

- (NSString *)hf_json:(id)obj {
    if (!obj) return @"{}";
    if (![NSJSONSerialization isValidJSONObject:obj]) {
        return [NSString stringWithFormat:@"%@", obj];
    }
    NSData *d = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:nil];
    return d ? [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] : @"{}";
}

- (NSString *)hf_md5Upper:(NSString *)src {
    const char *c = src.UTF8String;
    unsigned char dig[CC_MD5_DIGEST_LENGTH];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(c, (CC_LONG)strlen(c), dig);
#pragma clang diagnostic pop
    NSMutableString *out = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [out appendFormat:@"%02X", dig[i]];
    }
    return out;
}

- (NSString *)hf_nonce {
    static NSString *chars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:16];
    for (int i = 0; i < 16; i++) {
        [s appendFormat:@"%C", [chars characterAtIndex:arc4random_uniform((uint32_t)chars.length)]];
    }
    return s;
}

- (NSString *)hf_signStringValue:(id)v {
    if (v == nil || v == [NSNull null]) return @"";
    if ([v isKindOfClass:[NSString class]]) return (NSString *)v;
    if ([v isKindOfClass:[NSNumber class]]) return [(NSNumber *)v stringValue];
    return [NSString stringWithFormat:@"%@", v];
}

/// Sign method 3: public (appId/deviceId/channel/nonce/version) + signData values,
/// reverse-sorted, join `;`, MD5(s1+salt) upper. (06 §3.4 + §4.2)
- (NSString *)hf_sign3WithAppId:(NSString *)appId
                       deviceId:(NSString *)deviceId
                        channel:(NSString *)channel
                          nonce:(NSString *)nonce
                        version:(NSString *)version
                       signData:(NSDictionary *)signData
                           path:(NSString *)path {
    NSMutableArray<NSString *> *vals = [NSMutableArray arrayWithObjects:
                                        [self hf_signStringValue:appId],
                                        [self hf_signStringValue:deviceId],
                                        [self hf_signStringValue:channel],
                                        [self hf_signStringValue:nonce],
                                        [self hf_signStringValue:version],
                                        nil];
    if ([signData isKindOfClass:[NSDictionary class]]) {
        [signData enumerateKeysAndObjectsUsingBlock:^(__unused id key, id obj, __unused BOOL *stop) {
            [vals addObject:[self hf_signStringValue:obj]];
        }];
    }
    NSArray *sorted = [vals sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [b compare:a];
    }];
    NSString *s1 = [sorted componentsJoinedByString:@";"];
    NSString *sign = [self hf_md5Upper:[s1 stringByAppendingString:[HFVaultSeal kBetaGrain]]];
    NSLog(@"[HFNexusPipe][Sign] path=%@ s1=%@ sign=%@", path, s1, sign);
    return sign;
}

- (NSDictionary *)hf_buildBody:(NSDictionary *)signData nonSign:(NSDictionary *)nonSignData path:(NSString *)path {
    NSString *appId = [HFVaultSeal kAlphaSeed];
    NSString *deviceId = [HFQuillVault hf_quillAnchor];
    NSString *channel = [HFVaultSeal kEpsilonLane];
    NSString *nonce = [self hf_nonce];
    NSString *version = [HFVaultSeal kDeltaRev];
    long long clientTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSDictionary *safeSign = [signData isKindOfClass:[NSDictionary class]] ? signData : @{};
    NSString *sign = [self hf_sign3WithAppId:appId
                                    deviceId:deviceId
                                     channel:channel
                                       nonce:nonce
                                     version:version
                                    signData:safeSign
                                        path:path];
    NSMutableDictionary *biz = [NSMutableDictionary dictionary];
    if ([signData isKindOfClass:[NSDictionary class]]) [biz addEntriesFromDictionary:signData];
    if ([nonSignData isKindOfClass:[NSDictionary class]]) [biz addEntriesFromDictionary:nonSignData];
    NSMutableDictionary *body = [@{
        @"appId": appId,
        @"deviceId": deviceId ?: @"",
        @"channel": channel,
        @"nonce": nonce,
        @"version": version,
        @"clientTime": @(clientTime).stringValue,
        @"os": @([HFVaultSeal kZetaOSFlag]).stringValue,
        @"sign": sign,
        @"userId": [HFQuillVault hf_quillUid] ?: @"",
        @"token": [HFQuillVault hf_quillGate] ?: @"",
        @"clientVersion": [HFVaultSeal kIotaBundleRev],
        @"clientLanguage": [HFVaultSeal kEtaTongue]
    } mutableCopy];
    body[[HFVaultSeal kThetaBizSlot]] = biz.count ? biz : @{};
    return body;
}

- (void)hf_pipeBoot:(void (^)(BOOL))done {
    __weak typeof(self) weakSelf = self;
    [self hf_pipeWhenOnline:^(BOOL ok) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !ok) {
            NSLog(@"[HFNexusPipe][Boot] waiting network / failed");
            if (done) done(NO);
            return;
        }
        [[HFRealmGate shared] hf_realmBoot:^(NSString *baseURL) {
            NSLog(@"[HFNexusPipe][Boot] ready baseURL=%@", baseURL);
            if (done) done(YES);
        } fail:^(__unused NSError *error) {
            NSLog(@"[HFNexusPipe][Boot] failed");
            if (done) done(NO);
        }];
    }];
}

- (void)hf_handleBizCode:(NSString *)code msg:(NSString *)msg {
    if ([code isEqualToString:[HFVaultSeal eTokenExpired]] ||
        [code isEqualToString:[HFVaultSeal eTokenInvalid]] ||
        [code isEqualToString:[HFVaultSeal eUserMissing]]) {
        [HFQuillVault hf_quillErase];
        NSLog(@"[HFNexusPipe][Auth] token invalid, vault cleared");
        dispatch_async(dispatch_get_main_queue(), ^{
            for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
                if (s.activationState != UISceneActivationStateForegroundActive) continue;
                id<UISceneDelegate> d = s.delegate;
                if ([d isKindOfClass:[SceneDelegate class]]) {
                    [(SceneDelegate *)d hf_sceneShowGate];
                    break;
                }
            }
        });
        return;
    }
    if ([code isEqualToString:[HFVaultSeal eForceUpdate]]) {
        [self hf_pipeShowForceUpdate];
    }
}

- (void)hf_pipeShowForceUpdate {
    if (self.forceShowing) return;
    self.forceShowing = YES;
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pVersionV2]
                              signMap:@{}
                           nonSignMap:@{}
                           replyClass:[HFParcelVersionReply class]
                                   ok:^(HFParcelVersionReply *reply) {
        HFParcelVersion *ver = reply.data;
        if (![ver.updateType isEqualToString:@"2"]) {
            self.forceShowing = NO;
            return;
        }
        NSString *url = ver.latestVersionUrl ?: @"";
        dispatch_async(dispatch_get_main_queue(), ^{
            [[HFCurtainBox shared] hf_curtainForceUpdate:@"" storeURL:url];
        });
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[HFCurtainBox shared] hf_curtainForceUpdate:@"" storeURL:@""];
        });
    }];
}

- (BOOL)hf_isBizHalt:(HFParcelBase *)model {
    NSString *code = model.resultCodeText ?: @"";
    return [code isEqualToString:[HFVaultSeal eTokenExpired]] ||
           [code isEqualToString:[HFVaultSeal eTokenInvalid]] ||
           [code isEqualToString:[HFVaultSeal eUserMissing]] ||
           [code isEqualToString:[HFVaultSeal eForceUpdate]];
}

- (nullable id)hf_mapData:(id)data asClass:(Class)dataClass {
    if (!dataClass || !data) return data;
    return [dataClass yy_modelWithJSON:data];
}

- (void)hf_pipePost:(NSString *)path
            signMap:(NSDictionary *)signData
         nonSignMap:(NSDictionary *)nonSignData
                 ok:(HFNexusOK)ok
               fail:(HFNexusFail)fail {
    [self hf_pipePost:path signMap:signData nonSignMap:nonSignData dataClass:Nil ok:ok fail:fail];
}

- (void)hf_pipePost:(NSString *)path
            signMap:(NSDictionary *)signData
         nonSignMap:(NSDictionary *)nonSignData
          dataClass:(Class)dataClass
                 ok:(HFNexusOK)ok
               fail:(HFNexusFail)fail {
    [self hf_postInner:path signMap:signData nonSignMap:nonSignData replyClass:Nil dataClass:dataClass replyOK:nil dataOK:ok fail:fail];
}

- (void)hf_pipePost:(NSString *)path
            signMap:(NSDictionary *)signData
         nonSignMap:(NSDictionary *)nonSignData
         replyClass:(Class)replyClass
                 ok:(void (^)(id))ok
               fail:(HFNexusFail)fail {
    [self hf_postInner:path signMap:signData nonSignMap:nonSignData replyClass:replyClass dataClass:Nil replyOK:ok dataOK:nil fail:fail];
}

- (void)hf_postInner:(NSString *)path
             signMap:(NSDictionary *)signData
          nonSignMap:(NSDictionary *)nonSignData
          replyClass:(Class)replyClass
           dataClass:(Class)dataClass
             replyOK:(void (^)(id))replyOK
              dataOK:(HFNexusOK)dataOK
                fail:(HFNexusFail)fail {
    if (![self hf_pipeGuardOnlineOrFail:fail]) return;
    NSString *base = [[HFRealmGate shared] hf_realmCurrent];
    if (base.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
            if (fail) fail(nil, nil);
        });
        return;
    }
    NSString *url = [base stringByAppendingString:path];
    NSDictionary *body = [self hf_buildBody:signData nonSign:nonSignData path:path];
    NSLog(@"[HFNexusPipe][Request] path=%@ URL=%@", path, url);
    [self hf_logChunk:@"Params" body:[self hf_json:body]];
    [self.mgr.requestSerializer setValue:[HFProbeAtlas hf_probeUA] forHTTPHeaderField:@"User-Agent"];
    [self.mgr POST:url parameters:body headers:nil progress:nil success:^(__unused NSURLSessionDataTask *task, id responseObject) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)task.response;
        NSLog(@"[HFNexusPipe][Response] path=%@ URL=%@ Status=%ld", path, url, (long)http.statusCode);
        [self hf_logChunk:@"Body" body:[self hf_json:responseObject]];

        Class parseCls = replyClass ?: [HFParcelBase class];
        HFParcelBase *model = [parseCls yy_modelWithJSON:responseObject];
        if (![model isKindOfClass:[HFParcelBase class]]) {
            model = [HFParcelBase yy_modelWithJSON:responseObject];
        }
        NSString *codeStr = model.resultCodeText ?: @"";
        if ([self hf_isBizHalt:model]) {
            [self hf_handleBizCode:codeStr msg:model.resultMsg];
            dispatch_async(dispatch_get_main_queue(), ^{ if (fail) fail(model.resultMsg, codeStr); });
            return;
        }
        if (!model.hf_parcelAligned) {
            dispatch_async(dispatch_get_main_queue(), ^{ if (fail) fail(model.resultMsg, codeStr); });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (replyOK) {
                replyOK(model);
            } else if (dataOK) {
                dataOK([self hf_mapData:model.data asClass:dataClass]);
            }
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)task.response;
        NSInteger status = http.statusCode;
        NSLog(@"[HFNexusPipe][Response] path=%@ URL=%@ Error=%@ Status=%ld", path, url, error.localizedDescription, (long)status);
        BOOL offline = (error.code == NSURLErrorNotConnectedToInternet ||
                        error.code == NSURLErrorNetworkConnectionLost ||
                        error.code == NSURLErrorDataNotAllowed);
        dispatch_async(dispatch_get_main_queue(), ^{
            // Offline: no toast. Other transport errors: busy toast.
            if (!offline) {
                [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
            }
            if (fail) fail(nil, nil);
        });
    }];
}

- (void)hf_pipeUpload:(NSString *)path
              signMap:(NSDictionary *)signData
           nonSignMap:(NSDictionary *)nonSignData
             fileData:(NSData *)fileData
             fileName:(NSString *)fileName
             mimeType:(NSString *)mimeType
             progress:(void (^)(NSProgress *))progress
                   ok:(HFNexusOK)ok
                 fail:(HFNexusFail)fail {
    [self hf_pipeUpload:path signMap:signData nonSignMap:nonSignData fileData:fileData fileName:fileName mimeType:mimeType progress:progress dataClass:Nil ok:ok fail:fail];
}

- (void)hf_pipeUpload:(NSString *)path
              signMap:(NSDictionary *)signData
           nonSignMap:(NSDictionary *)nonSignData
             fileData:(NSData *)fileData
             fileName:(NSString *)fileName
             mimeType:(NSString *)mimeType
             progress:(void (^)(NSProgress *))progress
            dataClass:(Class)dataClass
                   ok:(HFNexusOK)ok
                 fail:(HFNexusFail)fail {
    if (![self hf_pipeGuardOnlineOrFail:fail]) return;
    NSString *base = [[HFRealmGate shared] hf_realmCurrent];
    if (base.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{ if (fail) fail(nil, nil); });
        return;
    }
    NSString *url = [base stringByAppendingString:path];
    NSDictionary *body = [self hf_buildBody:signData nonSign:nonSignData path:path];
    NSLog(@"[HFNexusPipe][Upload] path=%@ URL=%@ fileSize=%lu fileName=%@ mime=%@", path, url, (unsigned long)fileData.length, fileName, mimeType);
    [self hf_logChunk:@"Params" body:[self hf_json:body]];
    [self.mgr.requestSerializer setValue:[HFProbeAtlas hf_probeUA] forHTTPHeaderField:@"User-Agent"];
    [self.mgr POST:url parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [body enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:[HFVaultSeal kThetaBizSlot]]) return;
            NSString *v = [obj isKindOfClass:[NSString class]] ? obj : [NSString stringWithFormat:@"%@", obj];
            NSData *d = [v dataUsingEncoding:NSUTF8StringEncoding];
            [formData appendPartWithFormData:d name:key];
        }];
        NSData *empty = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
        [formData appendPartWithFormData:empty name:[HFVaultSeal kThetaBizSlot]];
        [formData appendPartWithFileData:fileData name:@"file" fileName:fileName mimeType:mimeType];
    } progress:progress success:^(__unused NSURLSessionDataTask *task, id responseObject) {
        HFParcelBase *model = [HFParcelBase yy_modelWithJSON:responseObject];
        NSString *codeStr = model.resultCodeText ?: @"";
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self hf_isBizHalt:model]) {
                [self hf_handleBizCode:codeStr msg:model.resultMsg];
                if (fail) fail(model.resultMsg, codeStr);
                return;
            }
            if (model.hf_parcelAligned) {
                if (ok) ok([self hf_mapData:model.data asClass:dataClass]);
            } else {
                if (fail) fail(model.resultMsg, codeStr);
            }
        });
    } failure:^(__unused NSURLSessionDataTask *task, __unused NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[HFOrbitHint shared] hf_orbitPulse:@"the system is busy. Please try again in 2 minutes."];
            if (fail) fail(nil, nil);
        });
    }];
}

@end
