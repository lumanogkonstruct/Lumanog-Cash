#import "HFProbeAtlas.h"
#import "HFCipherTag.h"
#import "HFVaultSeal.h"
#import <UIKit/UIKit.h>
#import <TargetConditionals.h>
#import <string.h>
#import <unistd.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <sys/mount.h>
#import <mach/mach.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <NetworkExtension/NetworkExtension.h>
#import <netinet/in.h>

@implementation HFProbeAtlas

+ (NSString *)hf_nullLit { return @"null"; }

+ (NSString *)hf_fill:(NSString *)v {
    if (![v isKindOfClass:[NSString class]] || v.length == 0) {
        return [self hf_nullLit];
    }
    return v;
}

+ (NSString *)hf_machine {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] ?: @"";
}

+ (NSString *)hf_modelFromIdentifier:(NSString *)identifier {
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"i386": @"iPhone Simulator", @"x86_64": @"iPhone Simulator", @"arm64": @"iPhone Simulator",
            @"iPhone1,1": @"iPhone", @"iPhone1,2": @"iPhone 3G", @"iPhone2,1": @"iPhone 3GS",
            @"iPhone3,1": @"iPhone 4", @"iPhone4,1": @"iPhone 4S", @"iPhone5,1": @"iPhone 5", @"iPhone5,2": @"iPhone 5",
            @"iPhone5,3": @"iPhone 5c", @"iPhone5,4": @"iPhone 5c", @"iPhone6,1": @"iPhone 5s", @"iPhone6,2": @"iPhone 5s",
            @"iPhone7,1": @"iPhone 6 Plus", @"iPhone7,2": @"iPhone 6", @"iPhone8,1": @"iPhone 6s", @"iPhone8,2": @"iPhone 6s Plus",
            @"iPhone8,4": @"iPhone SE", @"iPhone9,1": @"iPhone 7", @"iPhone9,3": @"iPhone 7", @"iPhone9,2": @"iPhone 7 Plus", @"iPhone9,4": @"iPhone 7 Plus",
            @"iPhone10,1": @"iPhone 8", @"iPhone10,4": @"iPhone 8", @"iPhone10,2": @"iPhone 8 Plus", @"iPhone10,5": @"iPhone 8 Plus",
            @"iPhone10,3": @"iPhone X", @"iPhone10,6": @"iPhone X", @"iPhone11,8": @"iPhone XR", @"iPhone11,2": @"iPhone XS", @"iPhone11,6": @"iPhone XS Max",
            @"iPhone12,1": @"iPhone 11", @"iPhone12,3": @"iPhone 11 Pro", @"iPhone12,5": @"iPhone 11 Pro Max", @"iPhone12,8": @"iPhone SE 2",
            @"iPhone13,1": @"iPhone 12 mini", @"iPhone13,2": @"iPhone 12", @"iPhone13,3": @"iPhone 12 Pro", @"iPhone13,4": @"iPhone 12 Pro Max",
            @"iPhone14,4": @"iPhone 13 mini", @"iPhone14,5": @"iPhone 13", @"iPhone14,2": @"iPhone 13 Pro", @"iPhone14,3": @"iPhone 13 Pro Max",
            @"iPhone14,6": @"iPhone SE 3", @"iPhone14,7": @"iPhone 14", @"iPhone14,8": @"iPhone 14 Plus",
            @"iPhone15,2": @"iPhone 14 Pro", @"iPhone15,3": @"iPhone 14 Pro Max", @"iPhone15,4": @"iPhone 15", @"iPhone15,5": @"iPhone 15 Plus",
            @"iPhone16,1": @"iPhone 15 Pro", @"iPhone16,2": @"iPhone 15 Pro Max",
            @"iPhone17,1": @"iPhone 16 Pro", @"iPhone17,2": @"iPhone 16 Pro Max", @"iPhone17,3": @"iPhone 16", @"iPhone17,4": @"iPhone 16 Plus", @"iPhone17,5": @"iPhone 16e",
            @"iPhone18,1": @"iPhone 17 Pro", @"iPhone18,2": @"iPhone 17 Pro Max", @"iPhone18,3": @"iPhone 17", @"iPhone18,4": @"iPhone 17 Air", @"iPhone18,5": @"iPhone 17e",
            @"iPhone19,2": @"iPhone 18 Pro", @"iPhone19,3": @"iPhone 18 Pro Max (USA)", @"iPhone19,7": @"iPhone 18 Pro Max", @"iPhone19,4": @"iPhone Duo",
        };
    });
    return map[identifier] ?: identifier;
}

+ (NSString *)hf_gb:(uint64_t)bytes {
    double gb = bytes / (1024.0 * 1024.0 * 1024.0);
    return [NSString stringWithFormat:@"%.6f", gb];
}

+ (uint64_t)hf_totalRam {
    return [NSProcessInfo processInfo].physicalMemory;
}

+ (uint64_t)hf_freeRam {
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    vm_statistics64_data_t vmstat;
    mach_port_t host = mach_host_self();
    if (host_statistics64(host, HOST_VM_INFO64, (host_info64_t)&vmstat, &count) != KERN_SUCCESS) {
        return 0;
    }
    return (uint64_t)vmstat.free_count * (uint64_t)vm_page_size;
}

+ (void)hf_disk:(uint64_t *)total free:(uint64_t *)freeBytes {
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    *total = [attr[NSFileSystemSize] unsignedLongLongValue];
    *freeBytes = [attr[NSFileSystemFreeSize] unsignedLongLongValue];
}

+ (long long)hf_bootMs {
    struct timeval boottime;
    size_t size = sizeof(boottime);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != 0) {
        return -1;
    }
    return (long long)boottime.tv_sec * 1000LL + boottime.tv_usec / 1000LL;
}

/// Awake time since boot (excludes sleep), milliseconds.
+ (long long)hf_wakeMs {
    NSTimeInterval up = [NSProcessInfo processInfo].systemUptime;
    if (up < 0) return -1;
    return (long long)llround(up * 1000.0);
}

+ (BOOL)hf_debugged {
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};
    struct kinfo_proc info;
    size_t size = sizeof(info);
    memset(&info, 0, sizeof(info));
    if (sysctl(mib, 4, &info, &size, NULL, 0) != 0) {
        return NO;
    }
    return (info.kp_proc.p_flag & P_TRACED) != 0;
}

+ (BOOL)hf_rooted {
    NSArray *paths = @[@"/Applications/Cydia.app", @"/Library/MobileSubstrate/MobileSubstrate.dylib", @"/bin/bash", @"/usr/sbin/sshd", @"/etc/apt"];
    for (NSString *p in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:p]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)hf_proxied {
    CFDictionaryRef proxy = CFNetworkCopySystemProxySettings();
    if (!proxy) return NO;
    NSDictionary *dict = (__bridge_transfer NSDictionary *)proxy;
    NSNumber *httpEnable = dict[(NSString *)kCFNetworkProxiesHTTPEnable];
    return httpEnable.boolValue;
}

+ (BOOL)hf_vpn {
    CFDictionaryRef proxy = CFNetworkCopySystemProxySettings();
    if (!proxy) return NO;
    NSDictionary *dict = (__bridge_transfer NSDictionary *)proxy;
    NSDictionary *scoped = dict[@"__SCOPED__"];
    if (![scoped isKindOfClass:[NSDictionary class]]) return NO;
    for (NSString *k in scoped.allKeys) {
        NSString *lk = k.lowercaseString;
        if ([lk containsString:@"tap"] || [lk containsString:@"tun"] || [lk containsString:@"ipsec"] || [lk containsString:@"ppp"]) {
            return YES;
        }
    }
    return NO;
}

+ (NSDictionary *)hf_wifiPair {
    __block NSString *ssid = @"";
    __block NSString *bssid = @"";
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_queue_t q = dispatch_queue_create("hf.probe.wifi", DISPATCH_QUEUE_SERIAL);
    dispatch_async(q, ^{
        if (@available(iOS 26.0, *)) {
            [NEHotspotNetwork fetchCurrentWithCompletionHandler:^(NEHotspotNetwork * _Nullable current) {
                if (current) {
                    ssid = current.SSID ?: @"";
                    bssid = current.BSSID ?: @"";
                }
                dispatch_semaphore_signal(sem);
            }];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
            for (NSString *ifnam in ifs) {
                NSDictionary *info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
                if (info[@"SSID"]) ssid = info[@"SSID"];
                if (info[@"BSSID"]) bssid = info[@"BSSID"];
            }
#pragma clang diagnostic pop
            dispatch_semaphore_signal(sem);
        }
    });
    dispatch_time_t t = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC));
    if ([NSThread isMainThread]) {
        // Never block main; leave empty.
    } else {
        dispatch_semaphore_wait(sem, t);
    }
    return @{@"ssid": ssid ?: @"", @"bssid": bssid ?: @""};
}

+ (NSString *)hf_networkType {
    // Reachability first: WiFi / WWAN / none — then cellular tech only when on WWAN.
    struct sockaddr_in zero = {0};
    zero.sin_len = sizeof(zero);
    zero.sin_family = AF_INET;
    SCNetworkReachabilityRef reach = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zero);
    if (!reach) return @"-99";
    SCNetworkReachabilityFlags flags = 0;
    BOOL ok = SCNetworkReachabilityGetFlags(reach, &flags);
    CFRelease(reach);
    if (!ok) return @"-99";
    BOOL reachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL needsConn = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
    if (!reachable || needsConn) return @"-99";
    BOOL wwan = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0;
    if (!wwan) return @"1"; // WiFi (or other non-cellular)

    CTTelephonyNetworkInfo *info = [CTTelephonyNetworkInfo new];
    NSString *radio = nil;
    if (@available(iOS 12.0, *)) {
        radio = info.serviceCurrentRadioAccessTechnology.allValues.firstObject;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (!radio) radio = info.currentRadioAccessTechnology;
#pragma clang diagnostic pop
    if (!radio) return @"-99";
    if ([radio containsString:@"NR"] || [radio containsString:@"5G"]) return @"5";
    if ([radio containsString:@"LTE"]) return @"4";
    if ([radio containsString:@"WCDMA"] || [radio containsString:@"HSDPA"] || [radio containsString:@"HSUPA"] || [radio containsString:@"CDMAEVDO"]) return @"3";
    if ([radio containsString:@"GPRS"] || [radio containsString:@"Edge"] || [radio containsString:@"CDMA1x"]) return @"2";
    return @"-99";
}

+ (NSDictionary<NSString *, id> *)hf_probeHarvest {
    NSString *anchor = [HFCipherTag hf_tagAnchor];
    UIDevice *dev = [UIDevice currentDevice];
    dev.batteryMonitoringEnabled = YES;
    uint64_t diskTotal = 0, diskFree = 0;
    [self hf_disk:&diskTotal free:&diskFree];
    long long bootMs = [self hf_bootMs];
    long long nowMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    long long upMs = bootMs > 0 ? (nowMs - bootMs) : -1; // includes sleep
    long long wakeMs = [self hf_wakeMs]; // screen-on / awake only
    CGFloat scale = UIScreen.mainScreen.scale;
    CGRect b = UIScreen.mainScreen.bounds;
    NSInteger sw = (NSInteger)(b.size.width * scale);
    NSInteger sh = (NSInteger)(b.size.height * scale);
    NSInteger bat = (dev.batteryState == UIDeviceBatteryStateUnknown) ? -1 : (NSInteger)lroundf(dev.batteryLevel * 100);
    NSString *machine = [self hf_machine];
    NSString *phoneType = [self hf_modelFromIdentifier:machine];
    NSDictionary *wifi = @{@"ssid": @"", @"bssid": @""};
    if (![NSThread isMainThread]) {
        wifi = [self hf_wifiPair];
    }
    NSString *lang = [NSLocale preferredLanguages].firstObject ?: @"en";
    if ([lang containsString:@"-"]) {
        lang = [lang componentsSeparatedByString:@"-"].firstObject;
    }
    NSMutableDictionary *m = [@{
        @"versionCode": [HFVaultSeal kIotaBundleRev],
        @"idfv": [HFCipherTag hf_tagVendor],
        @"uuid": anchor,
        @"ramTotal": [self hf_gb:[self hf_totalRam]],
        @"ramCanUse": [self hf_gb:[self hf_freeRam]],
        @"cashTotal": [self hf_gb:diskTotal],
        @"cashCanUse": [self hf_gb:diskFree],
        @"totalBootTimeWake": [NSString stringWithFormat:@"%lld", wakeMs],
        @"totalBootTime": [NSString stringWithFormat:@"%lld", upMs],
        @"batteryLevel": [NSString stringWithFormat:@"%ld", (long)bat],
        @"idfa": [HFCipherTag hf_tagAd],
        @"defaultTimeZone": [NSTimeZone localTimeZone].name ?: @"",
        @"debugged": [self hf_debugged] ? @"true" : @"false",
        @"simulated": (TARGET_OS_SIMULATOR != 0) ? @"true" : @"false",
        @"charged": (dev.batteryState == UIDeviceBatteryStateCharging || dev.batteryState == UIDeviceBatteryStateFull) ? @"true" : @"false",
        @"rooted": [self hf_rooted] ? @"true" : @"false",
        @"proxied": [self hf_proxied] ? @"true" : @"false",
        @"isvpn": [self hf_vpn] ? @"true" : @"false",
        @"screenResolution": [NSString stringWithFormat:@"%ld-%ld", (long)sw, (long)sh],
        @"screenWidth": [NSString stringWithFormat:@"%ld", (long)(NSInteger)b.size.width],
        @"screenHeight": [NSString stringWithFormat:@"%ld", (long)(NSInteger)b.size.height],
        @"systemVersions": dev.systemVersion ?: @"",
        @"wifiBssid": wifi[@"bssid"] ?: @"",
        @"wifiName": wifi[@"ssid"] ?: @"",
        @"network": [self hf_networkType],
        @"defaultLanguage": lang,
        @"phoneType": phoneType ?: @"",
        @"cpuNum": [NSString stringWithFormat:@"%lu", (unsigned long)[NSProcessInfo processInfo].processorCount],
        @"screenBrightness": [NSString stringWithFormat:@"%ld", (long)lroundf(UIScreen.mainScreen.brightness * 100)],
        @"lastBootTime": [NSString stringWithFormat:@"%lld", bootMs],
        @"phoneMark": dev.name ?: @"",
        @"deviceId": anchor
    } mutableCopy];
    // docs_phl/04 — 31 table keys + deviceId (same value as uuid)
    NSArray *keys32 = @[
        @"versionCode",@"idfv",@"uuid",@"ramTotal",@"ramCanUse",@"cashTotal",@"cashCanUse",
        @"totalBootTimeWake",@"totalBootTime",@"batteryLevel",@"idfa",@"defaultTimeZone",
        @"debugged",@"simulated",@"charged",@"rooted",@"proxied",@"isvpn",@"screenResolution",
        @"screenWidth",@"screenHeight",@"systemVersions",@"wifiBssid",@"wifiName",@"network",
        @"defaultLanguage",@"phoneType",@"cpuNum",@"screenBrightness",@"lastBootTime",@"phoneMark",
        @"deviceId"
    ];
    NSMutableDictionary *out = [NSMutableDictionary dictionaryWithCapacity:32];
    for (NSString *k in keys32) {
        out[k] = [self hf_fill:[NSString stringWithFormat:@"%@", m[k] ?: @""]];
    }
    return out;
}

+ (NSString *)hf_probeUA {
    NSString *appId = [HFVaultSeal kAlphaSeed];
    NSString *ver = [HFVaultSeal kIotaBundleRev];
    NSString *machine = [self hf_machine];
    NSString *model = [self hf_modelFromIdentifier:machine];
    NSString *kind = @"Mobile";
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        kind = @"Tablet";
    } else if ([machine hasPrefix:@"i386"] || [machine hasPrefix:@"x86_64"]) {
        kind = @"pc";
    }
    NSString *os = [UIDevice currentDevice].systemVersion;
    if (os.length == 0) os = @"";
    NSString *osPart = os.length ? [NSString stringWithFormat:@"iOS %@", os] : @"iOS";
    return [NSString stringWithFormat:@"%@/%@ (Apple; %@; %@; %@)", appId, ver, kind, model, osPart];
}

@end
