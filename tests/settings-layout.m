#import <Cocoa/Cocoa.h>
#import "SettingsStyle.h"
#import "Themer.h"
#import "Sizer.h"
#import "PrefsGeneralVC.h"
#import "PrefsEventsVC.h"
#import "PrefsAppearanceVC.h"
#import "PrefsAboutVC.h"
#define Check(x) do { if(!(x)) { NSLog(@"FAIL %d: %s",__LINE__,#x); return 1; } } while(0)
static NSInteger Cards(NSView *v) { NSInteger n=[v isKindOfClass:SettingsCard.class]; for(NSView *s in v.subviews)n+=Cards(s); return n; }
int main(void) { @autoreleasepool {
 [NSApplication sharedApplication]; [Themer shared]; [Sizer shared];
 // Check the actual window, not only isolated content views: titlebar must
 // never reveal unblurred text from windows behind it.
 NSPanel *window=[[NSPanel alloc] initWithContentRect:NSMakeRect(0,0,480,300) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
 StyleSettingsWindow(window);
 window.contentView=SettingsBackground();
 window.toolbar=[[NSToolbar alloc] initWithIdentifier:@"SettingsTestToolbar"];
 window.toolbarStyle=NSWindowToolbarStylePreference;
 [window layoutIfNeeded];
 Check(window.opaque);
 Check(!window.titlebarAppearsTransparent);
 Check(window.backgroundColor.alphaComponent==1.0);
 Check(((NSVisualEffectView *)window.contentView).blendingMode==NSVisualEffectBlendingModeWithinWindow);
 for(NSAppearanceName name in @[NSAppearanceNameAqua,NSAppearanceNameDarkAqua]) {
  for(Class cls in @[[PrefsGeneralVC class],[PrefsEventsVC class],[PrefsAppearanceVC class],[PrefsAboutVC class]]) {
   NSViewController *vc=[cls new]; NSView *v=vc.view; v.appearance=[NSAppearance appearanceNamed:name];
   NSSize fit=v.fittingSize; v.frame=NSMakeRect(0,0,MAX(480,fit.width),fit.height); [v layoutSubtreeIfNeeded];
   Check(fit.height>0 && fit.height<720); Check(fit.width<650);
   if(cls==PrefsGeneralVC.class) Check(Cards(v)==2);
   if(cls==PrefsEventsVC.class) Check(Cards(v)==2);
   if(cls==PrefsAppearanceVC.class) Check(Cards(v)==3);
   if(cls==PrefsAppearanceVC.class) {
    NSBitmapImageRep *image=[v bitmapImageRepForCachingDisplayInRect:v.bounds];
    [v cacheDisplayInRect:v.bounds toBitmapImageRep:image];
    NSString *file=[NSString stringWithFormat:@"work/settings-%@.png",name];
    [[image representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:file atomically:YES];
   }
   NSLog(@"%@ %@: %.0fx%.0f",NSStringFromClass(cls),name,MAX(480,fit.width),fit.height);
  }
 }
 puts("All settings tabs fit the common width in both appearances; section groups verified.");
} return 0; }
