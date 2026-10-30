#import "SettingsStyle.h"
@implementation SettingsCard
- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *shape=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds,.5,.5) xRadius:12 yRadius:12];
    [[NSColor.controlBackgroundColor colorWithAlphaComponent:.72] setFill]; [shape fill];
    [[NSColor.separatorColor colorWithAlphaComponent:.35] setStroke]; shape.lineWidth=1; [shape stroke];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; self.needsDisplay=YES; }
@end
NSVisualEffectView *SettingsBackground(void) {
    NSVisualEffectView *view=[NSVisualEffectView new];
    view.material=NSVisualEffectMaterialWindowBackground;
    view.blendingMode=NSVisualEffectBlendingModeWithinWindow;
    view.state=NSVisualEffectStateActive;
    return view;
}
void StyleSettingsWindow(NSWindow *window) {
    window.titlebarAppearsTransparent=NO;
    window.backgroundColor=NSColor.windowBackgroundColor;
    window.opaque=YES;
}
