#import <Cocoa/Cocoa.h>
#import "KoreanShortcutView.h"
#define Check(x) do { if(!(x)) { NSLog(@"FAIL %d: %s",__LINE__,#x); return 1; } } while(0)
int main(void) { @autoreleasepool {
 [NSApplication sharedApplication];
 NSBundle *bundle=[NSBundle bundleForClass:MASShortcutView.class];
 Check([[bundle localizedStringForKey:@"Record Shortcut" value:nil table:nil] isEqualToString:@"단축키 지정"]);
 MASShortcutView *recorder=[KoreanShortcutView new];

 NSLog(@"idle: %@, label: %@, help: %@",[recorder valueForKey:@"shortcutPlaceholder"],recorder.accessibilityLabel,recorder.accessibilityHelp);

 Check([recorder.accessibilityLabel isEqualToString:@"키보드 단축키 미지정"]);
 recorder.frame=NSMakeRect(0,0,240,25);
 NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,280,65) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
 [window.contentView addSubview:recorder];
 NSBitmapImageRep *image=[recorder bitmapImageRepForCachingDisplayInRect:recorder.bounds];
 [recorder cacheDisplayInRect:recorder.bounds toBitmapImageRep:image];
 [[image representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:@"work/shortcut-ko-idle.png" atomically:YES];
 recorder.recording=YES;
 NSLog(@"recording: %@",recorder.accessibilityLabel);
 Check([recorder.accessibilityLabel isEqualToString:@"키보드 단축키 입력 중"]);
 recorder.recording=NO;

 NSString *conflict=[bundle localizedStringForKey:@"The key combination %@ cannot be used" value:nil table:nil];
 Check(([[NSString stringWithFormat:conflict,@"⌘K"] isEqualToString:@"⌘K 키 조합을 사용할 수 없습니다"]));
 puts("Korean recorder idle/recording/cancel states and conflict text passed.");
} return 0; }
