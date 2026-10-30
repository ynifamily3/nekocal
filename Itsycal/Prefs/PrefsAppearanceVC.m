//
//  Created by Sanjay Madan on 1/11/17.
//  Copyright © 2017 mowglii.com. All rights reserved.
//

#import "PrefsAppearanceVC.h"
#import "SettingsStyle.h"
#import "EmojiRotation.h"
#import "MoUtils.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "Itsycal.h"
#import "Themer.h"
#import "Sizer.h"
#import "HighlightPicker.h"
#import "MoVFLHelper.h"
#import "IconIsConfigurableTransformer.h"

@implementation PrefsAppearanceVC
{
    NSTextField *_dateTimeFormat;
    NSButton *_hideIcon;
    NSWindowController *_emojiWindow;
    NSTextView *_emojiList;
    NSTextField *_emojiMinutes, *_emojiFormat, *_emojiPreview;
    NSButton *_emojiEnabled;
}

#pragma mark -
#pragma mark View lifecycle

- (void)loadView
{
    // View controller content view
    NSView *v = [NSView new];

    // Convenience function for making labels.
    NSTextField* (^label)(NSString*) = ^NSTextField* (NSString *stringValue) {
        NSTextField *txt = [NSTextField labelWithString:stringValue];
        [v addSubview:txt];
        return txt;
    };

    // Convenience function for making checkboxes.
    NSButton* (^chkbx)(NSString *) = ^NSButton* (NSString *title) {
        NSButton *chkbx = [NSButton checkboxWithTitle:title target:self action:nil];
        [v addSubview:chkbx];
        return chkbx;
    };

    // Convenience function for making popups whose selected item's
    // tag is bound to the NSUserDefaults value for key.
    NSPopUpButton* (^popup)(NSArray<NSString *> *, NSArray<NSNumber *> *, NSString *) = ^NSPopUpButton* (NSArray<NSString *> *titles, NSArray<NSNumber *> *tags, NSString *key) {
        NSParameterAssert(titles.count == tags.count);
        NSPopUpButton *popup = [NSPopUpButton new];
        [popup addItemsWithTitles:titles];
        for (NSUInteger i = 0; i < tags.count; i++) {
            [popup itemAtIndex:i].tag = tags[i].integerValue;
        }
        [popup bind:@"selectedTag" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:key] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];
        [v addSubview:popup];
        return popup;
    };

    // Theme popup. Each name includes "Theme" so the popup needs no label.
    NSPopUpButton *themePopup = popup(@[NSLocalizedString(@"System Theme", @"System theme name"),
                                        NSLocalizedString(@"Light Theme", @"Light theme name"),
                                        NSLocalizedString(@"Dark Theme", @"Dark theme name")],
                                      @[@(ThemePreferenceSystem), @(ThemePreferenceLight), @(ThemePreferenceDark)],
                                      kThemePreference);

    // Size segmented control. Each segment shows "Aa" at the font
    // size it selects. All images are as tall as the large font's
    // cap height so the three "Aa"s share a baseline.
    CGFloat fontSizes[] = {FONT_SIZE_SMALL, FONT_SIZE_MEDIUM, FONT_SIZE_LARGE};
    NSArray<NSString *> *sizeNames = @[NSLocalizedString(@"Small", @"Small text size"),
                                       NSLocalizedString(@"Medium", @"Medium text size"),
                                       NSLocalizedString(@"Large", @"Large text size")];
    CGFloat sizeImageHeight = ceil([NSFont systemFontOfSize:FONT_SIZE_LARGE].capHeight) + 2;
    NSMutableArray<NSImage *> *sizeImages = [NSMutableArray new];
    for (NSInteger i = 0; i < 3; i++) {
        NSDictionary *attrs = @{NSFontAttributeName: [NSFont systemFontOfSize:fontSizes[i]]};
        NSSize textSize = [@"Aa" sizeWithAttributes:attrs];
        NSImage *image = [NSImage imageWithSize:NSMakeSize(ceil(textSize.width), sizeImageHeight) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
            // Put the baseline 1pt above the bottom to leave room for overshoot.
            [@"Aa" drawAtPoint:NSMakePoint(0, 1 + [attrs[NSFontAttributeName] descender]) withAttributes:attrs];
            return YES;
        }];
        image.template = YES;
        image.accessibilityDescription = sizeNames[i];
        [sizeImages addObject:image];
    }
    NSSegmentedControl *sizePicker = [NSSegmentedControl segmentedControlWithImages:sizeImages trackingMode:NSSegmentSwitchTrackingSelectOne target:nil action:nil];
    for (NSInteger i = 0; i < 3; i++) [sizePicker setWidth:32 forSegment:i];
    [sizePicker.cell setAccessibilityLabel:NSLocalizedString(@"Size", @"Accessibility label for text size control")];
    [v addSubview:sizePicker];

    NSTextField *menubarLabel = label(NSLocalizedString(@"Menu Bar", @""));
    NSTextField *calendarLabel = label(NSLocalizedString(@"Calendar", @""));
    menubarLabel.font = [NSFont boldSystemFontOfSize:menubarLabel.font.pointSize-1];
    calendarLabel.font = [NSFont boldSystemFontOfSize:calendarLabel.font.pointSize-1];

    NSBox *separator0 = [NSBox new];
    NSBox *separator1 = [NSBox new];
    separator0.boxType = separator1.boxType = NSBoxSeparator;
    [v addSubview:separator0];
    [v addSubview:separator1];

    // Icon picker segmented control. The images are copies so the
    // accessibility descriptions don't change the shared images that
    // the menu bar also uses.
    NSArray<NSString *> *iconNames = @[NSLocalizedString(@"Filled date", @"Accessibility description for menu bar icon with the date in a filled square"),
                                       NSLocalizedString(@"Outlined date", @"Accessibility description for menu bar icon with the date in an outlined square"),
                                       NSLocalizedString(@"Calendar grid", @"Accessibility description for menu bar icon showing a grid of days"),
                                       NSLocalizedString(@"KawaiiCal face", @"Accessibility description for menu bar icon showing the KawaiiCal face")];
    NSMutableArray<NSImage *> *iconImages = [NSMutableArray new];
    for (NSInteger i = 0; i < iconNames.count; i++) {
        NSImage *image = [[NSImage imageNamed:[NSString stringWithFormat:@"menubaricon%ld", i]] copy];
        image.accessibilityDescription = iconNames[i];
        [iconImages addObject:image];
    }
    NSSegmentedControl *iconPicker = [NSSegmentedControl segmentedControlWithImages:iconImages trackingMode:NSSegmentSwitchTrackingSelectOne target:nil action:nil];
    [iconPicker.cell setAccessibilityLabel:NSLocalizedString(@"Menu bar icon", @"Accessibility label for menu bar icon picker")];
    [iconPicker setSelectedSegment:0]; // will be set by binding below.
    [v addSubview:iconPicker];

    // Checkboxes
    NSButton *showMonth = chkbx(NSLocalizedString(@"Show month in icon", @""));
    NSButton *showDayOfWeek = chkbx(NSLocalizedString(@"Show day of week in icon", @""));
    _hideIcon = chkbx(NSLocalizedString(@"Hide icon", @""));

    // Datetime format text field
    _dateTimeFormat = [NSTextField textFieldWithString:@""];
    _dateTimeFormat.placeholderString = NSLocalizedString(@"Datetime pattern", @"");
    _dateTimeFormat.refusesFirstResponder = YES;
    _dateTimeFormat.bezelStyle = NSTextFieldRoundedBezel;
    _dateTimeFormat.usesSingleLineMode = YES;
    _dateTimeFormat.delegate = self;
    [_dateTimeFormat.cell setAccessibilityLabel:NSLocalizedString(@"Menu bar date and time pattern", @"Accessibility label for menu bar datetime pattern text field")];
    [v addSubview:_dateTimeFormat];

    // Datetime help button
    NSButton *helpButton = [NSButton buttonWithTitle:@"" target:self action:@selector(openHelpPage:)];
    helpButton.bezelStyle = NSBezelStyleHelpButton;
    [v addSubview:helpButton];

    NSButton *emojiManage = [NSButton buttonWithTitle:@"이모티콘 관리…" target:self action:@selector(showEmojiSettings:)];
    [v addSubview:emojiManage];

    // First day of week label
    NSTextField *firstDayLabel = label(NSLocalizedString(@"First day of week:", @""));

    // First day of week popup
    NSPopUpButton *firstDayPopup = [NSPopUpButton new];
    [firstDayPopup addItemsWithTitles:@[NSLocalizedString(@"Sunday", @""),
                                        NSLocalizedString(@"Monday", @""),
                                        NSLocalizedString(@"Tuesday", @""),
                                        NSLocalizedString(@"Wednesday", @""),
                                        NSLocalizedString(@"Thursday", @""),
                                        NSLocalizedString(@"Friday", @""),
                                        NSLocalizedString(@"Saturday", @"")]];
    [firstDayPopup.cell setAccessibilityTitleUIElement:firstDayLabel.cell];
    [v addSubview:firstDayPopup];

    // Highlight control
    HighlightPicker *highlight = [HighlightPicker new];
    highlight.target = self;
    highlight.action = @selector(didChangeHighlight:);
    [v addSubview:highlight];

    // Calendar checkboxes
    NSButton *outlineMonth = chkbx(NSLocalizedString(@"Outline current month", @""));
    NSButton *showEventDots = chkbx(NSLocalizedString(@"Show event dots", @""));
    NSButton *useColoredDots = chkbx(NSLocalizedString(@"Use colored dots", @""));
    NSButton *showWeeks = chkbx(NSLocalizedString(@"Show calendar weeks", @""));

    [separator0 removeFromSuperview]; [separator1 removeFromSuperview];
    SettingsCard *themeCard=[SettingsCard new], *menuCard=[SettingsCard new], *calendarCard=[SettingsCard new];
    for(NSView *card in @[themeCard,menuCard,calendarCard]) [v addSubview:card];
    for(NSView *item in @[themePopup,sizePicker]) [themeCard addSubview:item];
    for(NSView *item in @[menubarLabel,iconPicker,showMonth,showDayOfWeek,_dateTimeFormat,helpButton,_hideIcon,emojiManage]) [menuCard addSubview:item];
    for(NSView *item in @[calendarLabel,firstDayLabel,firstDayPopup,highlight,outlineMonth,showEventDots,useColoredDots,showWeeks]) [calendarCard addSubview:item];
    MoVFLHelper *outer=[[MoVFLHelper alloc] initWithSuperview:v metrics:nil views:NSDictionaryOfVariableBindings(themeCard,menuCard,calendarCard)];
    [outer :@"V:|-24-[themeCard]-14-[menuCard]-14-[calendarCard]-24-|"];
    [outer :@"H:|-24-[themeCard]-24-|"]; [outer :@"H:|-24-[menuCard]-24-|"]; [outer :@"H:|-24-[calendarCard]-24-|"];
    MoVFLHelper *a=[[MoVFLHelper alloc] initWithSuperview:themeCard metrics:nil views:NSDictionaryOfVariableBindings(themePopup,sizePicker)];
    [a :@"V:|-14-[themePopup]-14-|"];
    [a :@"H:|-16-[themePopup]-(>=24)-[sizePicker]-16-|" :NSLayoutFormatAlignAllCenterY];
    MoVFLHelper *b=[[MoVFLHelper alloc] initWithSuperview:menuCard metrics:nil views:NSDictionaryOfVariableBindings(menubarLabel,iconPicker,showMonth,showDayOfWeek,_dateTimeFormat,helpButton,_hideIcon,emojiManage)];
    [b :@"V:|-16-[menubarLabel]-12-[iconPicker]-8-[showMonth]-6-[showDayOfWeek]-10-[_dateTimeFormat]-8-[_hideIcon]-10-[emojiManage]-16-|"];
    [b :@"H:|-16-[_dateTimeFormat]-8-[helpButton]-16-|" :NSLayoutFormatAlignAllCenterY];
    [b :@"H:|-16-[iconPicker]-16-|"];
    for(NSString *f in @[@"H:|-16-[menubarLabel]-(>=16)-|",@"H:|-16-[showMonth]-(>=16)-|",@"H:|-16-[showDayOfWeek]-(>=16)-|",@"H:|-16-[_hideIcon]-(>=16)-|",@"H:|-16-[emojiManage]-(>=16)-|"]) [b :f];
    MoVFLHelper *c=[[MoVFLHelper alloc] initWithSuperview:calendarCard metrics:nil views:NSDictionaryOfVariableBindings(calendarLabel,firstDayLabel,firstDayPopup,highlight,outlineMonth,showEventDots,useColoredDots,showWeeks)];
    [c :@"V:|-16-[calendarLabel]-12-[firstDayPopup]-12-[highlight]-12-[outlineMonth]-6-[showEventDots]-6-[useColoredDots]-6-[showWeeks]-16-|"];
    [c :@"H:|-16-[firstDayLabel]-12-[firstDayPopup]-(>=16)-|" :NSLayoutFormatAlignAllCenterY];
    for(NSString *f in @[@"H:|-16-[calendarLabel]-(>=16)-|",@"H:|-16-[highlight]-(>=16)-|",@"H:|-16-[outlineMonth]-(>=16)-|",@"H:|-16-[showEventDots]-(>=16)-|",@"H:|-36-[useColoredDots]-(>=16)-|",@"H:|-16-[showWeeks]-(>=16)-|"]) [c :f];

    // Binding for size preference. SizePreference values match segment indexes.
    [sizePicker bind:@"selectedIndex" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kSizePreference] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for icon preferences
    [iconPicker bind:@"selectedIndex" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kMenuBarIconType] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSNoSelectionPlaceholderBindingOption: @0}];
    [showMonth bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowMonthInIcon] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];
    [showDayOfWeek bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowDayOfWeekInIcon] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];
    [_hideIcon bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kHideIcon] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bind icon prefs enabled state to kHideIcon's value
    [iconPicker bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kHideIcon] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];
    [showMonth bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kHideIcon] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];
    [showDayOfWeek bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kHideIcon] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];

    // Bind icon prefs enabled state to kMenuBarIconType's value
    IconIsConfigurableTransformer *iconIsConfigurableTransformer = [IconIsConfigurableTransformer new];
    [showMonth bind:@"enabled2" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kMenuBarIconType] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSValueTransformerBindingOption: iconIsConfigurableTransformer}];
    [showDayOfWeek bind:@"enabled2" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kMenuBarIconType] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSValueTransformerBindingOption: iconIsConfigurableTransformer}];

    // Binding for datetime format
    [_dateTimeFormat bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kClockFormat] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSMultipleValuesPlaceholderBindingOption: _dateTimeFormat.placeholderString, NSNoSelectionPlaceholderBindingOption: _dateTimeFormat.placeholderString, NSNotApplicablePlaceholderBindingOption: _dateTimeFormat.placeholderString, NSNullPlaceholderBindingOption: _dateTimeFormat.placeholderString}];

    // Bindings for first day of week
    [firstDayPopup bind:@"selectedIndex" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kWeekStartDOW] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for highlight picker
    [highlight bind:@"weekStartDOW" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kWeekStartDOW] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];
    [highlight bind:@"selectedDOWs" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kHighlightedDOWs] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for outline current month preference. The checkbox
    // shows the opposite of kDoNotDrawOutlineAroundCurrentMonth.
    [outlineMonth bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kDoNotDrawOutlineAroundCurrentMonth] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES), NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];

    // Bindings for showEventDots preference
    [showEventDots bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowEventDots] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for useColoredDots preference
    [useColoredDots bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kUseColoredDots] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];
    [useColoredDots bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowEventDots] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for showWeeks preference
    [showWeeks bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowWeeks] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    self.view = v;
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self updateHideIconState];

    // We don't want _dateTimeFormat to be first responder.
    [self.view.window makeFirstResponder:nil];
}

- (void)openHelpPage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://mowglii.com/itsycal/datetime.html"]];
}

- (void)updateHideIconState
{
    NSString *dateTimeFormat = _dateTimeFormat.stringValue;
    if (dateTimeFormat == nil || [dateTimeFormat isEqualToString:@""]) {
        [_hideIcon setState:0];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kHideIcon];
        // Hack alert:
        // We call -performSelector... instead of calling _hideIcon's
        // -setEnabled: directly. Calling directly didn't work. Perhaps
        // this has to do with the fact that _hideIcon's value is bound
        // to NSUserDefaults which is mutated. By calling -setEnabled on
        // the next turn of the runloop, we are able to disbale _hideIcon.
        [self performSelectorOnMainThread:@selector(disableHideIcon:) withObject:nil waitUntilDone:NO];
    }
    else {
        [_hideIcon setEnabled:YES];
    }
}

- (void)disableHideIcon:(id)sender
{
    [_hideIcon setEnabled:NO];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    [self updateHideIconState];
}

- (void)didChangeHighlight:(HighlightPicker *)picker
{
    [[NSUserDefaults standardUserDefaults] setInteger:picker.selectedDOWs forKey:kHighlightedDOWs];
}

- (void)showEmojiSettings:(id)sender
{
    if (_emojiWindow) { [_emojiWindow showWindow:self]; return; }
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,500,560) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
    window.title=@"메뉴 막대 이모티콘";
    window.contentView=SettingsBackground();
    StyleSettingsWindow(window);
    _emojiWindow=[[NSWindowController alloc] initWithWindow:window];
    NSStackView *stack=[NSStackView new]; stack.orientation=NSUserInterfaceLayoutOrientationVertical; stack.alignment=NSLayoutAttributeLeading; stack.spacing=10;
    stack.translatesAutoresizingMaskIntoConstraints=NO; [window.contentView addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:window.contentView.leadingAnchor constant:20], [stack.trailingAnchor constraintEqualToAnchor:window.contentView.trailingAnchor constant:-20], [stack.topAnchor constraintEqualToAnchor:window.contentView.topAnchor constant:20], [stack.bottomAnchor constraintEqualToAnchor:window.contentView.bottomAnchor constant:-20]]];
    _emojiEnabled=[NSButton checkboxWithTitle:@"이모티콘 자동 교체" target:nil action:nil]; _emojiEnabled.state=[d boolForKey:@"EmojiRotationEnabled"]; [stack addArrangedSubview:_emojiEnabled];
    _emojiMinutes=[NSTextField textFieldWithString:[NSString stringWithFormat:@"%zd",[d integerForKey:@"EmojiRotationMinutes"] ?: 10]];
    [_emojiMinutes.widthAnchor constraintEqualToConstant:60].active=YES;
    [_emojiMinutes.cell setAccessibilityLabel:@"교체 간격 (분)"];
    NSStackView *interval=[NSStackView stackViewWithViews:@[[NSTextField labelWithString:@"교체 간격"],_emojiMinutes,[NSTextField labelWithString:@"분 (1~1440)"]]]; [stack addArrangedSubview:interval];
    [stack addArrangedSubview:[NSTextField labelWithString:@"한 줄에 하나씩 입력하세요. 같은 항목은 한 번만 저장됩니다."]];
    NSScrollView *scroll=[NSScrollView new]; scroll.hasVerticalScroller=YES; scroll.borderType=NSBezelBorder;
    _emojiList=[[NSTextView alloc] initWithFrame:NSMakeRect(0,0,400,150)]; _emojiList.richText=NO; _emojiList.font=[NSFont systemFontOfSize:15]; _emojiList.automaticQuoteSubstitutionEnabled=NO; _emojiList.automaticDashSubstitutionEnabled=NO;
    _emojiList.verticallyResizable=YES; _emojiList.horizontallyResizable=NO; _emojiList.autoresizingMask=NSViewWidthSizable;
    _emojiList.textContainer.containerSize=NSMakeSize(400,CGFLOAT_MAX); _emojiList.textContainer.widthTracksTextView=YES;
    [_emojiList setAccessibilityLabel:@"이모티콘 목록"];
    _emojiList.string=[[d arrayForKey:@"EmojiRotationEntries"] ?: EmojiRotation.defaultEntries componentsJoinedByString:@"\n"];
    scroll.documentView=_emojiList; [stack addArrangedSubview:scroll]; [scroll.heightAnchor constraintEqualToConstant:150].active=YES; [scroll.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active=YES;
    NSButton *import=[NSButton buttonWithTitle:@"CSV 불러오기…" target:self action:@selector(importEmojiCSV:)];
    NSButton *shuffle=[NSButton buttonWithTitle:@"지금 바꾸기" target:self action:@selector(shuffleEmoji:)];
    [stack addArrangedSubview:[NSStackView stackViewWithViews:@[import,shuffle]]];
    [stack addArrangedSubview:[NSTextField labelWithString:@"메뉴 막대 형식 · {emoji} 위치에 이모티콘을 표시합니다."]];
    NSString *format=[d stringForKey:kClockFormat];
    _emojiFormat=[NSTextField textFieldWithString:[format containsString:@"{emoji}"] ? format : @"{emoji} HH:mm"];
    [_emojiFormat.cell setAccessibilityLabel:@"이모티콘과 날짜 시간 형식"];
    [stack addArrangedSubview:_emojiFormat]; [_emojiFormat.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active=YES;
    _emojiPreview=[NSTextField labelWithString:@"적용을 누르면 목록·간격·메뉴 막대 형식이 저장됩니다."]; _emojiPreview.font=[NSFont systemFontOfSize:11]; [stack addArrangedSubview:_emojiPreview];
    NSButton *restore=[NSButton buttonWithTitle:@"이전 형식 복원" target:self action:@selector(restoreEmojiFormat:)];
    NSButton *apply=[NSButton buttonWithTitle:@"적용" target:self action:@selector(applyEmojiSettings:)]; apply.keyEquivalent=@"\r";
    [stack addArrangedSubview:[NSStackView stackViewWithViews:@[restore,apply]]];
    [window center]; [_emojiWindow showWindow:self];
}
- (void)emojiError:(NSString *)message
{
    NSAlert *alert=[NSAlert new]; alert.messageText=@"이모티콘 설정"; alert.informativeText=message; [alert runModal];
}
- (void)applyEmojiSettings:(id)sender
{
    NSMutableOrderedSet *entries=[NSMutableOrderedSet new];
    for(NSString *line in [_emojiList.string componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *s=[line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if(s.length>200) { [self emojiError:@"각 이모티콘은 200자 이내로 입력해 주세요."]; return; }
        if(s.length) [entries addObject:s];
    }
    NSInteger minutes=0; NSScanner *scanner=[NSScanner scannerWithString:_emojiMinutes.stringValue];
    if(![scanner scanInteger:&minutes] || !scanner.isAtEnd || minutes<1 || minutes>1440 || !entries.count || entries.count>500) { [self emojiError:@"목록은 1~500개, 교체 간격은 1~1440분으로 입력해 주세요."]; return; }
    if(![_emojiFormat.stringValue containsString:@"{emoji}"]) { [self emojiError:@"메뉴 막대 형식에 {emoji}를 넣어 주세요. 예: {emoji} HH:mm"]; return; }
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    if([d objectForKey:@"EmojiPreviousClockFormat"]==nil) [d setObject:[d stringForKey:kClockFormat] ?: @"" forKey:@"EmojiPreviousClockFormat"];
    [d setObject:entries.array forKey:@"EmojiRotationEntries"]; [d setInteger:minutes forKey:@"EmojiRotationMinutes"]; [d setBool:_emojiEnabled.state==NSControlStateValueOn forKey:@"EmojiRotationEnabled"];
    [d setObject:_emojiFormat.stringValue forKey:kClockFormat];
    [d setObject:NSUUID.UUID.UUIDString forKey:@"EmojiRotationRevision"];
    _emojiList.string=[entries.array componentsJoinedByString:@"\n"];
    [self updateEmojiPreview];
}
- (void)updateEmojiPreview
{
    NSDateFormatter *f=[NSDateFormatter new]; f.locale=DisplayLocale();
    _emojiPreview.stringValue=[@"현재 표시: " stringByAppendingString:[EmojiRotation.shared renderPattern:_emojiFormat.stringValue date:NSDate.date formatter:f]];
}
- (void)shuffleEmoji:(id)sender { [EmojiRotation.shared shuffleNow]; [self updateEmojiPreview]; }
- (void)restoreEmojiFormat:(id)sender
{
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    NSString *format=[d stringForKey:@"EmojiPreviousClockFormat"];
    if(format==nil) return;
    [d setBool:NO forKey:@"EmojiRotationEnabled"];
    if(format.length) [d setObject:format forKey:kClockFormat]; else [d removeObjectForKey:kClockFormat];
    _emojiEnabled.state=NSControlStateValueOff;
    [d setObject:NSUUID.UUID.UUIDString forKey:@"EmojiRotationRevision"];
    _emojiPreview.stringValue=@"이전 메뉴 막대 형식을 복원했습니다.";
}
- (void)importEmojiCSV:(id)sender
{
    NSOpenPanel *panel=[NSOpenPanel openPanel]; panel.allowedContentTypes=@[UTTypeCommaSeparatedText]; panel.allowsMultipleSelection=NO;
    [panel beginSheetModalForWindow:_emojiWindow.window completionHandler:^(NSModalResponse result) {
        if(result!=NSModalResponseOK) return;
        NSError *error=nil;
        NSNumber *size=nil; [panel.URL getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
        if(!size || size.unsignedLongLongValue>1024*1024) { [self emojiError:@"1MB 이하의 UTF-8 CSV 파일을 선택해 주세요."]; return; }
        NSString *csv=[NSString stringWithContentsOfURL:panel.URL encoding:NSUTF8StringEncoding error:&error];
        NSArray *entries=csv ? [EmojiRotation entriesFromCSV:csv error:&error] : nil;
        if(!entries) { [self emojiError:error.localizedDescription]; return; }
        self->_emojiList.string=[entries componentsJoinedByString:@"\n"];
        self->_emojiPreview.stringValue=@"불러왔습니다. 적용을 눌러 현재 목록을 교체하세요.";
    }];
}

@end
