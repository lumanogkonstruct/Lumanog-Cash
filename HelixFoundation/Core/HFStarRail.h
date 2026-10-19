#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HFStarRail;

@protocol HFStarRailDelegate <NSObject>
@optional
- (void)hf_starRail:(HFStarRail *)rail didPick:(NSInteger)score;
@end

/// 41 — five-star rating view (`two_icon_rate` / `two_icon_rate_not`)
@interface HFStarRail : UIView

@property (nonatomic, assign, readonly) NSInteger hf_score; // 0～5
@property (nonatomic, assign) CGFloat hf_starSide;          // default 36
@property (nonatomic, assign) CGFloat hf_starGap;           // default 12
@property (nonatomic, weak, nullable) id<HFStarRailDelegate> hf_delegate;
@property (nonatomic, copy, nullable) void (^hf_onPick)(NSInteger score);

- (void)hf_starSet:(NSInteger)score animated:(BOOL)animated;
- (void)hf_starReset:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
