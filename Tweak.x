#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DPDamageView : UIView
@end

@implementation DPDamageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.userInteractionEnabled = NO;
    }

    return self;
}

- (void)drawRect:(CGRect)rect {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat scale = UIScreen.mainScreen.scale;

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    NSArray *positions = @[
        @0.08, @0.17, @0.31, @0.47,
        @0.63, @0.79, @0.92
    ];

    for (NSUInteger i = 0; i < positions.count; i++) {
        CGFloat x = [positions[i] floatValue] * width;

        BOOL green = (i % 2 == 0);

        UIColor *color = green
        ? [UIColor colorWithRed:0.1 green:1.0 blue:0.3 alpha:0.27]
        : [UIColor colorWithRed:0.75 green:0.1 blue:1.0 alpha:0.27];

        CGContextSetFillColorWithColor(ctx, color.CGColor);

        CGFloat lineWidth = (i % 3 + 1) * scale;

        CGContextFillRect(
            ctx,
            CGRectMake(x, 0, lineWidth, height)
        );

        CGContextSetFillColorWithColor(
            ctx,
            [UIColor colorWithWhite:0 alpha:0.12].CGColor
        );

        CGContextFillRect(
            ctx,
            CGRectMake(x + lineWidth, 0, scale, height)
        );
    }

    // Едва заметная рябь
    CGContextSetFillColorWithColor(
        ctx,
        [UIColor colorWithWhite:1 alpha:0.018].CGColor
    );

    for (CGFloat y = 0; y < height; y += 6 * scale) {
        CGContextFillRect(
            ctx,
            CGRectMake(0, y, width, scale * 0.4)
        );
    }
}

@end


@interface DPOverlayController : UIViewController
@end

@implementation DPOverlayController

- (void)loadView {
    self.view = [[DPDamageView alloc]
        initWithFrame:UIScreen.mainScreen.bounds];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end


@interface DPOverlayManager : NSObject

@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) NSTimer *timer;

@end


@implementation DPOverlayManager

+ (instancetype)shared {
    static DPOverlayManager *manager;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        manager = [DPOverlayManager new];
    });

    return manager;
}

- (void)install {
    if (self.window) return;

    self.window = [[UIWindow alloc]
        initWithFrame:UIScreen.mainScreen.bounds];

    self.window.windowLevel = UIWindowLevelAlert + 1;
    self.window.backgroundColor = UIColor.clearColor;
    self.window.opaque = NO;
    self.window.userInteractionEnabled = NO;

    self.window.rootViewController = [DPOverlayController new];
    self.window.hidden = NO;

    self.timer = [NSTimer scheduledTimerWithTimeInterval:25
        target:self
        selector:@selector(glitch)
        userInfo:nil
        repeats:YES];
}

- (void)glitch {
    UIView *view = self.window.rootViewController.view;

    if (!view) return;

    CGFloat offsetX = (CGFloat)(arc4random_uniform(7)) - 3.0;
    CGFloat offsetY = (CGFloat)(arc4random_uniform(5)) - 2.0;

    [UIView animateWithDuration:0.12 animations:^{
        view.alpha = 0.65;
        view.transform = CGAffineTransformMakeTranslation(
            offsetX, offsetY
        );
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            view.alpha = 1.0;
            view.transform = CGAffineTransformIdentity;
        }];
    }];
}

@end


%ctor {
    @autoreleasepool {
        if ([NSBundle.mainBundle.bundleIdentifier
            isEqualToString:@"com.apple.springboard"]) {

            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                dispatch_get_main_queue(), ^{
                    [[DPOverlayManager shared] install];
                }
            );
        }
    }
}
