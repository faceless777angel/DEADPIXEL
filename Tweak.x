
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <math.h>

static char kDPDamageLayerKey;

typedef struct {
    CGFloat x;
    CGFloat widthPixels;
    CGFloat alpha;
    int color;
} DPColumn;

static void DPSetColor(CGContextRef ctx, int color, CGFloat alpha) {
    switch (color) {
        case 0:
            CGContextSetRGBFillColor(ctx, 0.10, 1.00, 0.28, alpha);
            break;
        case 1:
            CGContextSetRGBFillColor(ctx, 0.76, 0.12, 1.00, alpha);
            break;
        case 2:
            CGContextSetRGBFillColor(ctx, 0.12, 0.42, 1.00, alpha);
            break;
        case 3:
            CGContextSetRGBFillColor(ctx, 1.00, 0.12, 0.18, alpha);
            break;
        default:
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, alpha);
            break;
    }
}

static void DPFill(
    CGContextRef ctx,
    CGFloat x,
    CGFloat y,
    CGFloat width,
    CGFloat height,
    int color,
    CGFloat alpha
) {
    CGFloat scale = UIScreen.mainScreen.scale;
    if (scale <= 0) scale = 2.0;

    CGRect rect = CGRectMake(
        round(x * scale) / scale,
        round(y * scale) / scale,
        MAX(1.0, round(width * scale)) / scale,
        MAX(1.0, round(height * scale)) / scale
    );

    DPSetColor(ctx, color, alpha);
    CGContextFillRect(ctx, rect);
}

@interface DPDamageLayer : CALayer
@end

@implementation DPDamageLayer

- (instancetype)init {
    self = [super init];

    if (self) {
        self.name = @"DEADPIXEL_DAMAGE";
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor.CGColor;
        self.contentsScale = UIScreen.mainScreen.scale;
        self.needsDisplayOnBoundsChange = YES;
    }

    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    CGFloat scale = self.contentsScale;
    if (scale <= 0) scale = UIScreen.mainScreen.scale;
    if (width <= 0 || height <= 0) return;

    CGFloat pixel = 1.0 / scale;

    CGContextSaveGState(ctx);
    CGContextSetShouldAntialias(ctx, NO);
    CGContextSetAllowsAntialiasing(ctx, NO);

    // Основные повреждённые вертикальные субпиксели.
    static const DPColumn columns[] = {
        {0.0780, 1, 0.27, 0},
        {0.0790, 1, 0.09, 1},

        {0.1930, 1, 0.23, 1},
        {0.1940, 1, 0.08, 2},

        {0.3470, 1, 0.25, 0},
        {0.3480, 1, 0.08, 2},

        {0.5040, 1, 0.19, 1},
        {0.5050, 1, 0.07, 0},

        {0.6640, 1, 0.29, 0},
        {0.6650, 1, 0.10, 1},

        {0.8120, 1, 0.23, 1},
        {0.8130, 1, 0.08, 2},

        {0.9130, 1, 0.24, 0}
    };

    for (NSUInteger i = 0;
         i < sizeof(columns) / sizeof(columns[0]);
         i++) {

        const DPColumn *line = &columns[i];

        DPFill(
            ctx,
            line->x * width,
            0,
            line->widthPixels * pixel,
            height,
            line->color,
            line->alpha
        );
    }

    // Слабые цветные ореолы вокруг некоторых линий.
    DPFill(ctx, 0.077 * width, 0, 2 * pixel, height, 0, 0.035);
    DPFill(ctx, 0.192 * width, 0, 2 * pixel, height, 1, 0.035);
    DPFill(ctx, 0.663 * width, 0, 2 * pixel, height, 1, 0.04);
    DPFill(ctx, 0.811 * width, 0, 2 * pixel, height, 0, 0.035);

    // Неравномерные затемнения внутри повреждённых колонок.
    DPFill(ctx, 0.078 * width, 0.17 * height,
           2 * pixel, 0.14 * height, 4, 0.10);

    DPFill(ctx, 0.193 * width, 0.55 * height,
           2 * pixel, 0.09 * height, 4, 0.08);

    DPFill(ctx, 0.347 * width, 0.31 * height,
           2 * pixel, 0.19 * height, 4, 0.09);

    DPFill(ctx, 0.664 * width, 0.08 * height,
           2 * pixel, 0.12 * height, 4, 0.08);

    DPFill(ctx, 0.812 * width, 0.68 * height,
           2 * pixel, 0.13 * height, 4, 0.10);

    // Короткие горизонтальные срывы изображения.
    DPFill(ctx, 0.071 * width, 0.225 * height,
           0.027 * width, pixel, 0, 0.22);

    DPFill(ctx, 0.187 * width, 0.571 * height,
           0.019 * width, pixel, 1, 0.19);

    DPFill(ctx, 0.339 * width, 0.395 * height,
           0.034 * width, pixel, 2, 0.17);

    DPFill(ctx, 0.655 * width, 0.145 * height,
           0.031 * width, pixel, 0, 0.20);

    DPFill(ctx, 0.805 * width, 0.724 * height,
           0.025 * width, pixel, 1, 0.19);

    // Ещё несколько почти незаметных локальных артефактов.
    DPFill(ctx, 0.075 * width, 0.225 * height,
           0.018 * width, pixel, 4, 0.12);

    DPFill(ctx, 0.660 * width, 0.146 * height,
           0.013 * width, pixel, 4, 0.10);

    CGContextRestoreGState(ctx);
}

@end

static BOOL DPShouldSkipProcess(void) {
    NSString *bundleID =
        NSBundle.mainBundle.bundleIdentifier.lowercaseString;

    if (bundleID.length == 0) return YES;

    NSArray *excluded = @[
        @"org.coolstar.sileo",
        @"com.saurik.cydia",
        @"xyz.willy.zebra",
        @"com.opa334.dopamine"
    ];

    if ([excluded containsObject:bundleID]) return YES;

    NSString *extension =
        NSBundle.mainBundle.bundleURL.pathExtension.lowercaseString;

    if ([extension isEqualToString:@"appex"]) return YES;

    if (NSClassFromString(@"UIApplication") == Nil) return YES;

    return NO;
}

static BOOL DPWindowIsAllowed(UIWindow *window) {
    if (!window) return NO;
    if (window.hidden || window.alpha < 0.01) return NO;

    // Не затрагиваем клавиатуры и системные окна
    // с повышенным или пониженным уровнем.
    if (fabs(window.windowLevel - UIWindowLevelNormal) > 0.01) {
        return NO;
    }

    if (!window.rootViewController) return NO;

    NSString *className =
        NSStringFromClass(window.class).lowercaseString;

    NSArray *excludedClasses = @[
        @"keyboard",
        @"texteffects",
        @"remote",
        @"alert"
    ];

    for (NSString *word in excludedClasses) {
        if ([className containsString:word]) return NO;
    }

    return YES;
}

static void DPInstallDamageLayer(UIWindow *window) {
    if (![NSThread isMainThread]) return;
    if (!DPWindowIsAllowed(window)) return;

    CALayer *host = window.layer;
    CGRect hostBounds = host.bounds;

    if (CGRectIsEmpty(hostBounds)) return;

    DPDamageLayer *damage =
        objc_getAssociatedObject(window, &kDPDamageLayerKey);

    BOOL created = NO;

    if (!damage) {
        damage = [DPDamageLayer layer];
        damage.zPosition = 9999.0;

        objc_setAssociatedObject(
            window,
            &kDPDamageLayerKey,
            damage,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC
        );

        created = YES;
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    damage.bounds = CGRectMake(
        0,
        0,
        CGRectGetWidth(hostBounds),
        CGRectGetHeight(hostBounds)
    );

    damage.position = CGPointMake(
        CGRectGetMidX(hostBounds),
        CGRectGetMidY(hostBounds)
    );

    if (damage.superlayer != host) {
        [host addSublayer:damage];
    }

    [CATransaction commit];

    if (created) {
        [damage setNeedsDisplay];
    }
}

%group DPWindowHooks

%hook UIWindow

- (void)layoutSubviews {
    %orig;
    DPInstallDamageLayer(self);
}

- (void)makeKeyAndVisible {
    %orig;
    DPInstallDamageLayer(self);
}

- (void)setRootViewController:(UIViewController *)controller {
    %orig;
    DPInstallDamageLayer(self);
}

- (void)setHidden:(BOOL)hidden {
    %orig;

    if (!hidden) {
        DPInstallDamageLayer(self);
    }
}

%end

%end

%ctor {
    @autoreleasepool {
        if (DPShouldSkipProcess()) return;

        %init(DPWindowHooks);

        dispatch_async(dispatch_get_main_queue(), ^{
    UIApplication *application =
        [UIApplication sharedApplication];

    for (UIScene *scene in application.connectedScenes) {

        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }

        UIWindowScene *windowScene = (UIWindowScene *)scene;

        for (UIWindow *window in windowScene.windows) {
            DPInstallDamageLayer(window);
        }
    }
});
    }
}
