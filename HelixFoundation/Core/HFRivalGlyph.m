#import "HFRivalGlyph.h"
#import <UIKit/UIKit.h>

@implementation HFRivalGlyph

/// docs_phl/50 §4.2 — must-check schemes (all every run)
+ (NSArray<NSString *> *)hf_rivalMustSchemes {
    return @[
        @"apaylater", @"billease", @"megapeso", @"cashalo", @"hcphapp", @"Cashola",
        @"juanhand", @"pesoloan", @"skyro", @"linkedin", @"com.jobstreet.jobstreet",
        @"gcash", @"bpiRuby", @"seabankph", @"unionbank", @"com.rcbc.mobile.sit",
        @"landbank", @"tonikapp"
    ];
}

/// Random pool (Info.plist declares 27 = must 18 + pool 9); each run pick 5～9
+ (NSArray<NSString *> *)hf_rivalPoolSchemes {
    return @[
        @"paymaya", @"gotyme", @"paypal", @"remitly", @"arionplay", @"fafafagold",
        @"slots.games.vegas.night.casino", @"cashmancasino", @"itms-beta"
    ];
}

+ (NSArray<NSString *> *)hf_rivalTargets {
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    void (^add)(NSString *) = ^(NSString *s) {
        NSString *t = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (!t.length || [seen containsObject:t]) return;
        [seen addObject:t];
        [out addObject:t];
    };
    for (NSString *s in [self hf_rivalMustSchemes]) add(s);

    NSMutableArray<NSString *> *pool = [[self hf_rivalPoolSchemes] mutableCopy];
    for (NSUInteger i = pool.count; i > 1; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)i);
        [pool exchangeObjectAtIndex:i - 1 withObjectAtIndex:j];
    }
    NSUInteger pick = 5 + arc4random_uniform(6); // 5～10 inclusive
    if (pick > pool.count) pick = pool.count;
    for (NSUInteger i = 0; i < pick; i++) add(pool[i]);
    return out;
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)hf_rivalProbeRows {
    NSMutableArray *rows = [NSMutableArray array];
    for (NSString *scheme in [self hf_rivalTargets]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", scheme]];
        if (!url) continue;
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [rows addObject:@{ @"appName": scheme }];
        }
    }
    return rows;
}

@end
