//
//  ItsycalWindow.m
//  Itsycal
//
//  Created by Sanjay Madan on 12/14/14.
//  Copyright (c) 2014 mowglii.com. All rights reserved.
//

#import "ItsycalWindow.h"
#import <QuartzCore/QuartzCore.h>
#import "Themer.h"

static const CGFloat kMinimumSpaceBetweenWindowAndScreenEdge = 10;
// Arrow geometry follows NSPopover's: straight 45° sides, a rounded
// tip and small concave fillets where it meets the body. kArrowHeight
// is the space reserved above the body; the rounded tip ends ~0.5pt
// below it.
static const CGFloat kArrowHeight  = 11;
static const CGFloat kArrowSideHeight = 11.5; // before rounding the tip
static const CGFloat kArrowTipRadius = 2.5;
static const CGFloat kArrowBaseRadius = 3;
static const CGFloat kCornerRadius = 16;
static const CGFloat kVerticalPadding = 11;
static const CGFloat kOpenScale = 0.85;
static const CFTimeInterval kOpenDuration = 0.3;

// A noninteractive tint reduces wallpaper bleed without dimming the text.
@interface PopupTintView : NSView
@property (nonatomic, readonly) NSColor *tintColor;
@end
@implementation PopupTintView
- (BOOL)allowsVibrancy { return NO; }
- (NSView *)hitTest:(NSPoint)point { return nil; }
- (NSColor *)tintColor { return [Theme.mainBackgroundColor colorWithAlphaComponent:0.55]; }
- (void)drawRect:(NSRect)dirtyRect {
    [self.tintColor setFill];
    NSRectFillUsingOperation(self.bounds, NSCompositingOperationSourceOver);
}
- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    self.needsDisplay = YES;
}
@end

@interface ItsycalWindowFrameView : NSVisualEffectView
@property (nonatomic, assign) CGFloat arrowMidX;
@property (nonatomic, readonly) NSPoint arrowTip;
@end

#pragma mark -
#pragma mark ItsycalWindow

// =========================================================================
// ItsycalWindow
// =========================================================================

@implementation ItsycalWindow

- (id)init
{
    self = [super initWithContentRect:NSZeroRect styleMask:NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO];
    if (self) {
        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        [self setLevel:NSMainMenuWindowLevel];
        [self setMovableByWindowBackground:NO];
        [self setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
        // Fade out when -[NSWindow orderOut:] is called.
        [self setAnimationBehavior:NSWindowAnimationBehaviorUtilityWindow];
        // The frame view draws the window. Its safe area excludes
        // the arrow and padding, so views placed in the window should
        // be constrained to its safeAreaLayoutGuide. The system draws
        // the window's shadow around the frame view's shape.
        [self setContentView:[ItsycalWindowFrameView new]];
    }
    return self;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (void)positionRelativeToRect:(NSRect)rect screenMaxX:(CGFloat)screenMaxX
{
    // Calculate window's top left point.
    // First, center window under status item.
    CGFloat w = NSWidth(self.frame);
    CGFloat x = roundf(NSMidX(rect) - w / 2);
    CGFloat y = NSMinY(rect) - 2;
    
    // If the calculated x position puts the window too
    // far to the right, shift the window left.
    if (x + w + kMinimumSpaceBetweenWindowAndScreenEdge > screenMaxX) {
        x = screenMaxX - w - kMinimumSpaceBetweenWindowAndScreenEdge;
    }

    // Set the window position.
    [self setFrameTopLeftPoint:NSMakePoint(x, y)];

    // Tell the frame view where to draw the arrow.
    ItsycalWindowFrameView *frameView = (ItsycalWindowFrameView *)self.contentView;
    frameView.arrowMidX = NSMidX([self convertRectFromScreen:rect]);
    
    [self invalidateShadow];
}

- (void)makeKeyAndOrderFrontAnimated
{
    if (self.visible) {
        [self makeKeyAndOrderFront:nil];
        return;
    }
    ItsycalWindowFrameView *frameView = (ItsycalWindowFrameView *)self.contentView;
    [frameView layoutSubtreeIfNeeded];
    CALayer *layer = frameView.layer;
    BOOL reduceMotion = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;

    self.alphaValue = 0;
    [self makeKeyAndOrderFront:nil];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = reduceMotion ? 0.15 : 0.18;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        self.animator.alphaValue = 1;
    }];
    if (reduceMotion || layer == nil) return;

    // Grow out of the arrow tip like NSPopover. The scale is about
    // the tip, expressed relative to the layer's anchor point.
    NSPoint tip = frameView.arrowTip;
    CGSize size = layer.bounds.size;
    CGFloat dx = tip.x - layer.anchorPoint.x * size.width;
    CGFloat dy = tip.y - layer.anchorPoint.y * size.height;
    CATransform3D from = CATransform3DMakeTranslation(dx, dy, 0);
    from = CATransform3DScale(from, kOpenScale, kOpenScale, 1);
    from = CATransform3DTranslate(from, -dx, -dy, 0);

    CASpringAnimation *grow = [CASpringAnimation animationWithKeyPath:@"transform"];
    grow.fromValue = [NSValue valueWithCATransform3D:from];
    grow.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    grow.mass = 1;
    grow.stiffness = 420;
    grow.damping = 34;
    grow.duration = MAX(grow.settlingDuration, kOpenDuration);
    [layer removeAnimationForKey:@"open"];
    [layer addAnimation:grow forKey:@"open"];
}

@end

#pragma mark -
#pragma mark ItsycalWindowFrameView

// =========================================================================
// ItsycalWindowFrameView
// =========================================================================

@implementation ItsycalWindowFrameView
{
    CAShapeLayer *_shapeMask;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        self.material = NSVisualEffectMaterialPopover;
        self.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        self.state = NSVisualEffectStateActive;
        self.wantsLayer = YES;
        PopupTintView *tint = [[PopupTintView alloc] initWithFrame:self.bounds];
        tint.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:tint];
        self.additionalSafeAreaInsets = NSEdgeInsetsMake(kArrowHeight + kVerticalPadding, 0, kVerticalPadding, 0);

        // The window's shape is a rounded body with a little arrow at
        // the top. Masking our layer to that shape clips the material,
        // the tint and the content's corners. Masks use only alpha, so
        // any opaque color works.
        _shapeMask = [CAShapeLayer layer];
        _shapeMask.fillColor = NSColor.blackColor.CGColor;
        self.layer.mask = _shapeMask;
    }
    return self;
}

- (void)setArrowMidX:(CGFloat)arrowMidX
{
    _arrowMidX = arrowMidX;
    [self updateMask];
}

- (void)layout
{
    [super layout];
    [self updateMask];
}

- (void)updateMask
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    NSRect bounds = self.bounds;
    NSRect bodyRect = bounds;
    bodyRect.size.height -= kArrowHeight;
    // Add the arrow to the body if its right edge is inside
    // the right edge of the body (taking into account the corner
    // radius). This accounts for the edge-case where Itsycal is
    // all the way to the right in the menu bar. This is possible
    // if the user has a 3rd party app like Bartender.
    // Body and arrow are one closed outline, so there is no seam
    // or overlap where they meet.
    CGFloat minX = NSMinX(bodyRect), maxX = NSMaxX(bodyRect);
    CGFloat minY = NSMinY(bodyRect), top = NSMaxY(bodyRect);
    CGFloat r = MIN(kCornerRadius, MIN(NSWidth(bodyRect), NSHeight(bodyRect)) / 2);
    CGFloat m = (_arrowMidX == 0) ? NSMidX(bounds) : _arrowMidX;
    CGFloat h = kArrowSideHeight;
    CGFloat halfBase = h + kArrowBaseRadius;
    BOOL hasArrow = (m + halfBase < maxX - r) && (m - halfBase > minX + r);

    NSBezierPath *shape = [NSBezierPath bezierPath];
    [shape moveToPoint:NSMakePoint(minX + r, minY)];
    [shape appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) toPoint:NSMakePoint(maxX, top) radius:r];
    [shape appendBezierPathWithArcFromPoint:NSMakePoint(maxX, top) toPoint:NSMakePoint(minX, top) radius:r];
    if (hasArrow) {
        [shape lineToPoint:NSMakePoint(m + halfBase, top)];
        [shape appendBezierPathWithArcFromPoint:NSMakePoint(m + h, top) toPoint:NSMakePoint(m, top + h) radius:kArrowBaseRadius];
        [shape appendBezierPathWithArcFromPoint:NSMakePoint(m, top + h) toPoint:NSMakePoint(m - h, top) radius:kArrowTipRadius];
        [shape appendBezierPathWithArcFromPoint:NSMakePoint(m - h, top) toPoint:NSMakePoint(m - halfBase, top) radius:kArrowBaseRadius];
    }
    [shape appendBezierPathWithArcFromPoint:NSMakePoint(minX, top) toPoint:NSMakePoint(minX, minY) radius:r];
    [shape appendBezierPathWithArcFromPoint:NSMakePoint(minX, minY) toPoint:NSMakePoint(maxX, minY) radius:r];
    [shape closePath];
    _arrowTip = NSMakePoint(m, hasArrow ? top + h - kArrowTipRadius * (M_SQRT2 - 1) : top);

    _shapeMask.frame = bounds;
    _shapeMask.path = shape.CGPath;

    [CATransaction commit];

    // The layer mask only clips what this process draws. WindowServer
    // composites the behind-window material and the window shadow
    // itself, and without maskImage it uses the whole window
    // rectangle: the shadow then outlines a rectangle and the corners
    // and the area beside the arrow read as a pale box.
    self.maskImage = NSIsEmptyRect(bounds) ? nil : [NSImage imageWithSize:bounds.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [NSColor.blackColor setFill];
        [shape fill];
        return YES;
    }];
    [self.window invalidateShadow];
}

@end
