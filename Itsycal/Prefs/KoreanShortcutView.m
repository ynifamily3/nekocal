#import "KoreanShortcutView.h"
#import "MoUtils.h"
@implementation KoreanShortcutView
- (NSString *)accessibilityLabel {
    if (![DisplayLocale().languageCode isEqualToString:@"ko"]) return super.accessibilityLabel;
    if (self.recording) return @"키보드 단축키 입력 중";
    if (!self.shortcutValue) return @"키보드 단축키 미지정";
    return [NSString stringWithFormat:@"키보드 단축키 %@%@",self.shortcutValue.modifierFlagsString,self.shortcutValue.keyCodeString ?: @""];
}
@end
