
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DPDamageLayer : CALayer
@end

@implementation DPDamageLayer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.needsDisplayOnBoundsChange = YES;
        self.contentsScale = UIScreen.mainScreen.scale;
        self.opaque = NO;
        self.name = @"DEADPIXEL_DAMAGE";
        self.drawsAsynchronously = YES;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat s = self.contentsScale;

    if (w <= 0 || h <= 0) return;

    // Небольшие неоднородные кластеры повреждённых субпикселей.
    struct DPLine {
        CGFloat x;
        CGFloat width;
        CGFloat alpha;
        int color;
    };

    static const struct DPLine lines[] = {
        {0.083, 0.45, 0.24, 0},
        {0.084, 0.25, 0.12, 1},
        {0.196, 0.35, 0.17, 1},
        {0.197, 0.20, 0.10, 2},
        {0.352, 0.55, 0.21, 0},
        {0.354, 0.22, 0.11, 2},
        {0.519, 0.35, 0.15, 1},
        {0.521, 0.20, 0.09, 0},
        {0.677, 0.50, 0.19, 0},
        {0.679, 0.20, 0.10, 2},
        {0.842, 0.40, 0.17, 1},
        {0.844, 0.20, 0.09, 2}
    };

    for (NSUInteger i = 0; i < sizeof(lines) / sizeof(lines[0]); i++) {
        const struct DPLine *p = &lines[i];

        UIColor *c;
        if (p->color == 0) {
            c = [UIColor colorWithRed:0.12 green:1.0 blue:0.32 alpha:p->alpha];
        } else if (p->color == 1) {
            c = [UIColor colorWithRed:0.72 green:0.12 blue:1.0 alpha:p->alpha];
        } else {
            c = [UIColor colorWithRed:0.15 green:0.45 blue:1.0 alpha:p->alpha];
        }

        CGContextSetFillColorWithColor(ctx, c.CGColor);
        CGContextFillRect(ctx, CGRectMake(
            p->x * w, 0, MAX(p->width / s, 0.35), h
        ));
    }

    // Едва заметные локальные тёмные повреждения.
    CGContextSetFillColorWithColor(
        ctx, [UIColor colorWithWhite:0 alpha:0.10].CGColor
    );

    CGContextFillRect(ctx, CGRectMake(w * 0.083, h * 0.28, 1.0, h * 0.13));
    CGContextFillRect(ctx, CGRectMake(w * 0.352, h * 0.61, 0.8, h * 0.08));
    CGContextFillRect(ctx, CGRectMake(w * 0.677, h * 0.18, 0.9, h * 0.17));

    // Короткие горизонтальные срывы изображения.
    CGContextSetFillColorWithColor(
        ctx, [UIColor colorWithRed:0.55 green:0.85 blue:0.75 alpha:0.07].CGColor
    );

    CGContextFillRect(ctx, CGRectMake(w * 0.075, h * 0.36, w * 0.035, 0.7));
    CGContextFillRect(ctx, CGRectMake(w * 0.345, h * 0.64, w * 0.025, 0.6));
    CGContextFillRect(ctx, CGRectMake(w * 0.668, h * 0.24, w * 0.04, 0.7));
}

@end

%hook UIWindow

- (void)layoutSubviews {
    %orig;

    // Не трогаем клавиатуру, системные диалоги и специальные окна.
    if (self.windowLevel != UIWindowLevelNormal) return;

    DPDamageLayer *damage = nil;

    for (CALayer *layer in self.layer.sublayers) {
        if ([layer.name isEqualToString:@"DEADPIXEL_DAMAGE"]) {
            damage = (DPDamageLayer *)layer;
            break;
        }
    }

    if (!damage) {
        damage = [DPDamageLayer layer];
        damage.frame = self.bounds;
        damage.contentsScale = UIScreen.mainScreen.scale;
        [self.layer addSublayer:damage];
    } else {
        damage.frame = self.bounds;
    }
}

%end
