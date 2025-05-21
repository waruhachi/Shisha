#include "Shisha.h"

%hook SBWallpaperController

- (id)init {
    id orig = %orig;
    wallpaperController = orig;
    return orig;
}

- (UIView *)_wallpaperViewForVariant:(NSInteger)variant {
    UIView *originalWallpaperView = %orig;

    // Only modify the home screen wallpaper (variant 1)
    if (variant == 1 && tweakEnabled) {
        // Get the image from the original wallpaper view
        if ([originalWallpaperView isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)originalWallpaperView;
            originalWallpaperImage = imageView.image;

            // Create our custom wallpaper view
            if (customWallpaperView == nil) {
                // Make the image slightly larger to allow for movement
                CGFloat scale = 1.2;
                CGSize newSize = CGSizeMake(
                    originalWallpaperImage.size.width * scale,
                    originalWallpaperImage.size.height * scale
                );

                UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
                [originalWallpaperImage drawInRect:CGRectMake(
                    (newSize.width - originalWallpaperImage.size.width) / 2,
                    (newSize.height - originalWallpaperImage.size.height) / 2,
                    originalWallpaperImage.size.width,
                    originalWallpaperImage.size.height
                )];
                UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();

                customWallpaperView = [[ParallaxWallpaperView alloc] initWithImage:newImage];
                customWallpaperView.frame = originalWallpaperView.frame;
                customWallpaperView.contentMode = UIViewContentModeScaleAspectFill;
                customWallpaperView.clipsToBounds = YES;
                customWallpaperView.initialCenter = customWallpaperView.center;
            }

            return customWallpaperView;
        }
    }

    return originalWallpaperView;
}

%end

%hook SBHomeScreenViewController

- (void)viewDidLoad {
    %orig;

    // Set up scroll view for tracking page changes
    UIScrollView *iconScrollView = nil;

    // Find the icon scroll view in the view hierarchy
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            iconScrollView = (UIScrollView *)subview;
            break;
        }
    }

    if (iconScrollView) {
        // Add scroll view delegate
        [iconScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"] && [object isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)object;
        CGPoint offset = scrollView.contentOffset;

        // Convert scrollview offset to wallpaper offset
        CGFloat scrollWidth = scrollView.contentSize.width - scrollView.frame.size.width;
        if (scrollWidth > 0 && customWallpaperView) {
            CGFloat progressX = offset.x / scrollWidth;
            CGFloat wallpaperOffsetX = progressX * customWallpaperView.maxOffset * 2 - customWallpaperView.maxOffset;

            [customWallpaperView scrollWithOffset:CGPointMake(wallpaperOffsetX, 0)];
        }
    }
    else {
        %orig;
    }
}

- (void)dealloc {
    // Clean up observers
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            [subview removeObserver:self forKeyPath:@"contentOffset"];
            break;
        }
    }
    %orig;
}

%end

%ctor {
    // This constructor is called when the tweak is loaded
    NSLog(@"ScrollingWallpaper tweak initialized");
}
