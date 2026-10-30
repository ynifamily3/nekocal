#import <Cocoa/Cocoa.h>
#import "ItsycalWindow.h"
#import "Sizer.h"
#import "Themer.h"
#import "MoCalendar.h"
#define Check(x) do { if(!(x)) { NSLog(@"FAIL line %d: %s",__LINE__,#x); return 1; } } while(0)
int main(void) { @autoreleasepool {
 [NSApplication sharedApplication]; [Themer shared]; [Sizer shared];
 ItsycalWindow *window=[ItsycalWindow new];
 Check([window.contentView isKindOfClass:NSVisualEffectView.class]);
 NSVisualEffectView *background=(NSVisualEffectView *)window.contentView;
 Check(background.material==NSVisualEffectMaterialPopover);
 Check(background.blendingMode==NSVisualEffectBlendingModeBehindWindow);
 Check(!window.opaque);
 NSView *tint=nil;
 for(NSView *v in background.subviews) if([v isKindOfClass:NSClassFromString(@"PopupTintView")]) tint=v;
 Check(tint!=nil);
 Check(fabs(((NSColor *)[tint valueForKey:@"tintColor"]).alphaComponent-0.55)<0.001);
 Check(!tint.allowsVibrancy);
 Check([tint hitTest:NSMakePoint(1,1)]==nil);
 Check(![MoCalendar new].isOpaque);
 for(NSInteger size=0;size<3;size++) {
  SizePref.sizePreference=size;
  for(NSAppearanceName name in @[NSAppearanceNameAqua,NSAppearanceNameDarkAqua]) {
   NSView *event=[NSClassFromString(@"AgendaEventCell") new];
   event.appearance=[NSAppearance appearanceNamed:name];
   NSTextField *title=[event valueForKey:@"titleTextField"];
   NSTextField *time=[event valueForKey:@"durationTextField"];
   NSTextField *location=[event valueForKey:@"locationTextField"];
   title.stringValue=@"고양이와 함께 산책하는 일정"; time.stringValue=@"오후 2:00~3:00"; location.stringValue=@"공원";
   event.frame=NSMakeRect(0,0,300,200); [event layoutSubtreeIfNeeded];
   Check(title.font.pointSize==SizePref.fontSize+1);
   Check(time.font.pointSize==SizePref.fontSize);
   Check(event.fittingSize.height>=title.intrinsicContentSize.height+time.intrinsicContentSize.height+8);
   NSGridView *grid=[event valueForKey:@"grid"]; Check(grid.rowSpacing==2);
   NSView *heading=[NSClassFromString(@"AgendaDateCell") new];
   Check([heading isKindOfClass:NSVisualEffectView.class]);
   Check(((NSVisualEffectView *)heading).material==NSVisualEffectMaterialHeaderView);
   Check(((NSVisualEffectView *)heading).blendingMode==NSVisualEffectBlendingModeWithinWindow);
   Check(((NSTextField *)[heading valueForKey:@"dayTextField"]).font.pointSize==SizePref.fontSize+1);
  }
 }
 puts("System material/backdrop, transparent calendar, sticky headers and three text sizes in light/dark appearances passed.");
} return 0; }
