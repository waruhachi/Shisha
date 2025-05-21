#include <UIKit/UIKit.h>
#include <SpringBoard/SpringBoard.h>

// Interface declarations for iOS classes we need to hook
@interface SBHomeScreenViewController : UIViewController
@end

@interface SBWallpaperController : NSObject
- (UIView *)_wallpaperViewForVariant:(NSInteger)variant;
@end

// Our custom image view for parallax scrolling
@interface ParallaxWallpaperView : UIImageView
@property (nonatomic, assign) CGFloat maxOffset;
@property (nonatomic, assign) CGPoint initialCenter;
@end

@implementation ParallaxWallpaperView
- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super initWithImage:image]) {
        self.maxOffset = 50.0; // Default offset value
        self.initialCenter = self.center;
    }
    return self;
}

- (void)scrollWithOffset:(CGPoint)offset {
    CGFloat xOffset = fmax(fmin(offset.x, self.maxOffset), -self.maxOffset);
    CGFloat yOffset = fmax(fmin(offset.y, self.maxOffset), -self.maxOffset);

    self.center = CGPointMake(
        self.initialCenter.x + xOffset,
        self.initialCenter.y + yOffset
    );
}
@end

// Global variables
static SBWallpaperController *wallpaperController;
static ParallaxWallpaperView *customWallpaperView;
static UIImage *originalWallpaperImage;
static BOOL tweakEnabled = YES;
