
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
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat scale = UIScreen.mainScreen.scale;

    NSArray *positions = @[
        @0.06, @0.15, @0.25, @0.37, @0.49,
        @0.61, @0.73, @0.85, @0.94
    ];

    for (NSUInteger i = 0; i < positions.count; i++) {
        CGFloat x = [positions[i] floatValue] * w;
        BOOL green = (i % 2 == 0);

        UIColor *color = green
        ? [UIColor colorWithRed:0.05 green:1.0 blue:0.25 alpha:0.32]
        : [UIColor colorWithRed:0.75 green:0.05 blue:1.0 alpha:0.32];

        CGFloat lineWidth = (i % 3 + 1) * scale;

        CGContextSetFillColorWithColor(ctx, color.CGColor);
        CGContextFillRect(ctx, CGRectMake(x, 0, lineWidth, h));

        CGContextSetFillColorWithColor(
            ctx,
            [UIColor colorWithWhite:0 alpha:0.18].CGColor
        );
        CGContextFillRect(
            ctx,
            CGRectMake(x + lineWidth, 0, scale, h)
        );
    }

    // Лёгкая горизонтальная рябь
    CGContextSetFillColorWithColor(
        ctx,
        [UIColor colorWithWhite:1 alpha:0.025].CGColor
    );

    for (CGFloat y = 0; y < h; y += 7 * scale) {
        CGContextFillRect(
            ctx,
            CGRectMake(0, y, w, scale * 0.5)
        );
    }
}

@end

@interface DPPassthroughWindow : UIWindow
@end

@implementation DPPassthroughWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}

@end

@interface DPOverlayManager : NSObject

@property(nonatomic, strong) DPPassthroughWindow *window;
@property(nonatomic, strong) NSTimer *timer;

- (void)install;
- (void)tryInstall;

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

- (void)tryInstall {
    if (self.window) return;

    UIWindowScene *scene = nil;

    for (UIScene *candidate in
         UIApplication.sharedApplication.connectedScenes) {
        if ([candidate isKindOfClass:UIWindowScene.class] &&
            candidate.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)candidate;
            break;
        }
    }

    if (!scene) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{
                [self tryInstall];
            }
        );
        return;
    }

    self.window = [[DPPassthroughWindow alloc] initWithWindowScene:scene];

    self.window.frame = scene.coordinateSpace.bounds;
    self.window.windowLevel = UIWindowLevelAlert + 1;
    self.window.backgroundColor = UIColor.clearColor;
    self.window.opaque = NO;
    self.window.userInteractionEnabled = YES;

    UIViewController *controller = [UIViewController new];
    controller.view = [[DPDamageView alloc] initWithFrame:self.window.bounds];
    controller.view.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.window.rootViewController = controller;
    self.window.hidden = NO;

    self.timer = [NSTimer scheduledTimerWithTimeInterval:25
        target:self
        selector:@selector(glitch)
        userInfo:nil
        repeats:YES];
}

- (void)install {
    if (self.window) return;
    [self tryInstall];
}

- (void)glitch {
    UIView *view = self.window.rootViewController.view;
    if (!view) return;

    CGFloat x = (CGFloat)arc4random_uniform(7) - 3.0;
    CGFloat y = (CGFloat)arc4random_uniform(5) - 2.0;

    [UIView animateWithDuration:0.12 animations:^{
        view.alpha = 0.65;
        view.transform = CGAffineTransformMakeTranslation(x, y);
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
                dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                dispatch_get_main_queue(), ^{
                    [[DPOverlayManager shared] install];
                }
            );
        }
    }
}
