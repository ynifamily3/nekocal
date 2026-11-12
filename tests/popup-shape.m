// The popup's outline: a rounded body plus an NSPopover-like arrow drawn
// as one path, so nothing shows through where the arrow meets the body.
//
//   xcrun clang -fobjc-arc -framework Cocoa -framework QuartzCore -I Itsycal -I Itsycal/MoCode \
//     tests/popup-shape.m Itsycal/ItsycalWindow.m Itsycal/Themer.m Itsycal/MoUtils.m \
//     -o work/popup-shape-check && work/popup-shape-check
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "ItsycalWindow.h"
#import "Themer.h"
#define Check(x) do { if(!(x)) { NSLog(@"FAIL line %d: %s",__LINE__,#x); return 1; } } while(0)

// Coverage of the layer mask at a point, rendered the way Core Animation does.
static int LayerAlpha(CALayer *mask, NSSize size, NSPoint p) {
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(cs);
    [mask renderInContext:ctx];
    uint8_t *data = CGBitmapContextGetData(ctx);
    size_t row = CGBitmapContextGetBytesPerRow(ctx);
    // Bitmap contexts are y-up when rendered from a layer with no flip.
    int a = data[(size_t)floor(size.height - p.y) * row + (size_t)p.x * 4 + 3];
    CGContextRelease(ctx);
    return a;
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication]; [Themer shared];
    ItsycalWindow *window = [ItsycalWindow new];
    [window setContentSize:NSMakeSize(300, 200)];
    NSVisualEffectView *frame = (NSVisualEffectView *)window.contentView;
    [frame layoutSubtreeIfNeeded];
    // Status item at the window's horizontal center, just above it.
    NSRect item = NSMakeRect(NSMidX(window.frame) - 10, NSMaxY(window.frame) + 2, 20, 22);
    [window positionRelativeToRect:item screenMaxX:10000];
    [frame layoutSubtreeIfNeeded];

    NSSize size = frame.bounds.size;
    CALayer *mask = frame.layer.mask;
    Check(mask != nil);
    CGFloat bodyTop = size.height - 11;  // kArrowHeight
    CGFloat mid = size.width / 2;
    NSPoint inside[] = { {mid, size.height / 2}, {20, 20}, {mid, bodyTop - 0.5}, {mid, bodyTop + 5}, {mid, bodyTop + 0.5}, {mid, bodyTop + 9.5}, {mid - 10, bodyTop + 0.5} };
    NSPoint outside[] = { {0, 0}, {size.width - 1, 0}, {0, size.height - 1}, {1, bodyTop - 1}, {size.width - 2, bodyTop - 1}, {40, bodyTop + 4}, {size.width - 40, bodyTop + 4}, {mid + 8, bodyTop + 7}, {mid - 9, bodyTop + 7} };
    for (int i = 0; i < 7; i++) {
        Check(LayerAlpha(mask, size, inside[i]) == 255);
    }
    for (int i = 0; i < 9; i++) {
        Check(LayerAlpha(mask, size, outside[i]) == 0);
    }

    // NSPopover-sized arrow: about 10.5pt above the body, measured
    // from the mask (topmost covered row beside vs. at the arrow).
    int bodyRows = 0, tipRows = 0;
    for (int y = (int)size.height - 1; y >= 0; y--) { if (LayerAlpha(mask, size, NSMakePoint(40, y + 0.5)) > 127) { bodyRows = y + 1; break; } }
    for (int y = (int)size.height - 1; y >= 0; y--) { if (LayerAlpha(mask, size, NSMakePoint(mid, y + 0.5)) > 127) { tipRows = y + 1; break; } }
    Check(tipRows - bodyRows >= 10 && tipRows - bodyRows <= 11);

    // The rounded tip ends just inside the window's top row, not clipped by it.
    int tipAlpha = LayerAlpha(mask, size, NSMakePoint(mid, size.height - 0.5));
    Check(tipAlpha > 0 && tipAlpha < 255);

    // Arrow is dropped when it would collide with the right corner.
    NSRect farRight = NSMakeRect(NSMaxX(window.frame) - 12, NSMaxY(window.frame) + 2, 20, 22);
    [window positionRelativeToRect:farRight screenMaxX:NSMaxX(window.frame) + 10];
    Check(LayerAlpha(mask, size, NSMakePoint(size.width - 12, bodyTop + 4)) == 0);
    Check(LayerAlpha(mask, size, NSMakePoint(mid, size.height / 2)) == 255);

    puts("Popup outline: rounded body and arrow form one solid shape; arrow drops near the corner.");
} return 0; }
