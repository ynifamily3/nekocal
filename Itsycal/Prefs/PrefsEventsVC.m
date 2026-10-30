//
//  Created by Sanjay Madan on 10/5/26.
//  Copyright © 2026 mowglii.com. All rights reserved.
//

#import "PrefsEventsVC.h"
#import "SettingsStyle.h"
#import "Itsycal.h"
#import "MoVFLHelper.h"
#import "EventCenter.h"

static NSString * const kSourceCellId = @"SourceCell";
static NSString * const kCalendarCellId = @"CalendarCell";

// Cell views for the Sources and Calendars table view.
@interface SourceCellView : NSView
@property (nonatomic) NSTextField *textField;
@end
@interface CalendarCellView : NSView
@property (nonatomic) NSButton *checkbox;
@property (nonatomic) NSButton *holidayCheckbox;
@end

#pragma mark -
#pragma mark PrefsEventsVC

// =========================================================================
// PrefsEventsVC
// =========================================================================

@implementation PrefsEventsVC
{
    NSTableView *_calendarsTV;
    NSTextField *_agendaDaysLabel;
    NSPopUpButton *_agendaDaysPopup;
    NSButton *_showLocation;
    NSButton *_showDaysWithoutEvents;
    NSArray *_sourcesAndCalendars;
}

#pragma mark -
#pragma mark View lifecycle

- (void)loadView
{
    // View controller content view
    NSView *v = [NSView new];

    // Convenience function for making checkboxes.
    NSButton* (^chkbx)(NSString *) = ^NSButton* (NSString *title) {
        NSButton *chkbx = [NSButton checkboxWithTitle:title target:self action:nil];
        [v addSubview:chkbx];
        return chkbx;
    };

    NSTextField *eventListLabel = [NSTextField labelWithString:NSLocalizedString(@"Event List", @"")];
    eventListLabel.font = [NSFont boldSystemFontOfSize:eventListLabel.font.pointSize-1];
    [v addSubview:eventListLabel];

    NSBox *separator = [NSBox new];
    separator.boxType = NSBoxSeparator;
    [v addSubview:separator];

    // Calendars table view
    _calendarsTV = [NSTableView new];
    _calendarsTV.headerView = nil;
    _calendarsTV.allowsColumnResizing = NO;
    _calendarsTV.intercellSpacing = NSMakeSize(0, 0);
    _calendarsTV.dataSource = self;
    _calendarsTV.delegate = self;
    _calendarsTV.style = NSTableViewStylePlain;
    [_calendarsTV addTableColumn:[[NSTableColumn alloc] initWithIdentifier:@"SourcesAndCalendars"]];

    // Calendars enclosing scrollview
    NSScrollView *tvContainer = [NSScrollView new];
    tvContainer.scrollerStyle = NSScrollerStyleLegacy;
    tvContainer.hasVerticalScroller = YES;
    tvContainer.documentView = _calendarsTV;
    tvContainer.borderType = NSLineBorder;
    [v addSubview:tvContainer];

    // Agenda days label
    _agendaDaysLabel = [NSTextField labelWithString:NSLocalizedString(@"Show:", @"Label for how many days the event list shows")];
    [v addSubview:_agendaDaysLabel];

    // Agenda days popup
    _agendaDaysPopup = [NSPopUpButton new];
    [_agendaDaysPopup addItemsWithTitles:@[NSLocalizedString(@"No events", @""),
                                     NSLocalizedString(@"1 day", @""),
                                     NSLocalizedString(@"2 days", @""),
                                     NSLocalizedString(@"3 days", @""),
                                     NSLocalizedString(@"4 days", @""),
                                     NSLocalizedString(@"5 days", @""),
                                     NSLocalizedString(@"6 days", @""),
                                     NSLocalizedString(@"7 days", @""),
                                     NSLocalizedString(@"14 days", @""),
                                     NSLocalizedString(@"31 days", @"")]];
    [_agendaDaysPopup.cell setAccessibilityTitleUIElement:_agendaDaysLabel.cell];
    [v addSubview:_agendaDaysPopup];

    // Checkboxes
    _showLocation = chkbx(NSLocalizedString(@"Show event location", @""));
    _showDaysWithoutEvents = chkbx(NSLocalizedString(@"Show days with no events", @""));

    [separator removeFromSuperview];
    SettingsCard *calendarsCard=[SettingsCard new], *listCard=[SettingsCard new];
    [v addSubview:calendarsCard]; [v addSubview:listCard];
    NSTextField *calendarsTitle=[NSTextField labelWithString:@"캘린더"];
    calendarsTitle.font=[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    NSTextField *hint=[NSTextField wrappingLabelWithString:@"목록에 표시할 캘린더와 공휴일로 사용할 캘린더를 선택하세요."];
    hint.font=[NSFont systemFontOfSize:11]; hint.textColor=NSColor.secondaryLabelColor;
    for(NSView *item in @[calendarsTitle,hint,tvContainer]) [calendarsCard addSubview:item];
    for(NSView *item in @[eventListLabel,_agendaDaysLabel,_agendaDaysPopup,_showLocation,_showDaysWithoutEvents]) [listCard addSubview:item];
    tvContainer.borderType=NSNoBorder; tvContainer.drawsBackground=NO; _calendarsTV.backgroundColor=NSColor.clearColor;
    MoVFLHelper *outer=[[MoVFLHelper alloc] initWithSuperview:v metrics:nil views:NSDictionaryOfVariableBindings(calendarsCard,listCard)];
    [outer :@"V:|-24-[calendarsCard]-16-[listCard]-24-|"];
    [outer :@"H:|-24-[calendarsCard]-24-|"]; [outer :@"H:|-24-[listCard]-24-|"];
    MoVFLHelper *a=[[MoVFLHelper alloc] initWithSuperview:calendarsCard metrics:nil views:NSDictionaryOfVariableBindings(calendarsTitle,hint,tvContainer)];
    [a :@"V:|-16-[calendarsTitle]-6-[hint]-12-[tvContainer(240)]-12-|"];
    [a :@"H:|-16-[calendarsTitle]-(>=16)-|"]; [a :@"H:|-16-[hint]-16-|"]; [a :@"H:|-8-[tvContainer]-8-|"];
    MoVFLHelper *b=[[MoVFLHelper alloc] initWithSuperview:listCard metrics:nil views:NSDictionaryOfVariableBindings(eventListLabel,_agendaDaysLabel,_agendaDaysPopup,_showLocation,_showDaysWithoutEvents)];
    [b :@"V:|-16-[eventListLabel]-12-[_agendaDaysPopup]-12-[_showLocation]-8-[_showDaysWithoutEvents]-16-|"];
    [b :@"H:|-16-[_agendaDaysLabel(112)]-12-[_agendaDaysPopup]-(>=16)-|" :NSLayoutFormatAlignAllCenterY];
    for(NSString *f in @[@"H:|-16-[eventListLabel]-(>=16)-|",@"H:|-16-[_showLocation]-(>=16)-|",@"H:|-16-[_showDaysWithoutEvents]-(>=16)-|"]) [b :f];

    // Bindings for agenda days
    [_agendaDaysPopup bind:@"selectedIndex" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowEventDays] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for showLocation preference
    [_showLocation bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowLocation] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for showDaysWithoutEvents preference
    [_showDaysWithoutEvents bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kShowDaysWithNoEventsInAgenda] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    self.view = v;
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    _sourcesAndCalendars = [self.ec sourcesAndCalendars];

    _calendarsTV.enabled = self.ec.calendarAccessGranted;
    _agendaDaysLabel.textColor = self.ec.calendarAccessGranted ? NSColor.labelColor : NSColor.disabledControlTextColor;
    _agendaDaysPopup.enabled = self.ec.calendarAccessGranted;
    _showLocation.enabled = self.ec.calendarAccessGranted;
    _showDaysWithoutEvents.enabled = self.ec.calendarAccessGranted;
}

- (void)viewDidAppear
{
    [super viewDidAppear];

    // We can properly measure row heights once the view has been laid out
    // and the width of the tableview is known. This tab may be appearing
    // for the first time, before any layout pass, so lay it out now.
    [self.view layoutSubtreeIfNeeded];
    [_calendarsTV reloadData];
}

#pragma mark -
#pragma mark Calendar

- (void)calendarClicked:(NSButton *)checkbox
{
    NSInteger row = checkbox.tag;
    BOOL selected = checkbox.state == NSControlStateValueOn;
    CalendarInfo *info = _sourcesAndCalendars[row];
    NSString *calendarIdentifier = info.calendar.calendarIdentifier;
    [self.ec updateSelectedCalendarsForIdentifier:calendarIdentifier selected:selected];
    
    _sourcesAndCalendars = [self.ec sourcesAndCalendars];
    [_calendarsTV reloadData];
}


- (void)holidayClicked:(NSButton *)checkbox
{
    CalendarInfo *info=_sourcesAndCalendars[checkbox.tag];
    [self.ec updateHolidayCalendarForIdentifier:info.calendar.calendarIdentifier holiday:checkbox.state==NSControlStateValueOn];
    [_calendarsTV reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    // If access is denied, return 1 row for a message about granting access.
    return self.ec.calendarAccessGranted ? [_sourcesAndCalendars count] : 1;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    // If access is denied, row height is the height of the tableview so we can
    // show some helpful message text.
    if (!self.ec.calendarAccessGranted) return 170.0;

    // Calculate the height of either the source title or the calendar title.
    // In the case of the source title, the available width is the full width
    // of the tablie view minus the left and right margins. In the case of the
    // calendar title, we have to make an adjustment to account for the space
    // occupied by the checkbox. We also add room for top and bottom margins
    // after the text height has been calculated.

    id obj = _sourcesAndCalendars[row];
    CGFloat tvWidth = NSWidth(_calendarsTV.frame);
    CGFloat textWidth = tvWidth - 4 - 4; // minus left & right margins
    NSString *str;

    if ([obj isKindOfClass:[CalendarInfo class]]) {
        str = ((CalendarInfo *)obj).calendar.title;
        textWidth -= 20.0; // account for checkbox
    } else {
        str = (NSString *)obj; // source title
    }
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:12]}];
    CGRect attrStrRect = [attrStr boundingRectWithSize:CGSizeMake(textWidth, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    return NSHeight(attrStrRect) + 4 + 4 + ([obj isKindOfClass:CalendarInfo.class] ? 23 : 0); // plus top & bottom margins
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    return NO;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    // If calendar access was denied, show a helpful message. We repurpose the
    // SourceCellView since it is just a textfield with nice margins.
    if (!self.ec.calendarAccessGranted) {
        SourceCellView *message = [tableView makeViewWithIdentifier:kSourceCellId owner:self];
        if (!message) message = [SourceCellView new];
        message.textField.lineBreakMode = NSLineBreakByWordWrapping;
        message.textField.font = [NSFont systemFontOfSize:12];
        message.textField.stringValue = NSLocalizedString(@"Calendar access denied.\n\nKawaiiCal is more useful when it can display events from your calendars. You can change this setting in System Settings › Privacy & Security › Calendars", @"");
        return message;
    }
    
    // Show a list of sources and calendars with checkboxes.
    
    NSView *v = nil;
    id obj = _sourcesAndCalendars[row];
    
    if ([obj isKindOfClass:[NSString class]]) {
        SourceCellView *source = [tableView makeViewWithIdentifier:kSourceCellId owner:self];
        if (!source) source = [SourceCellView new];
        source.textField.stringValue = (NSString *)obj;
        v = source;
    }
    else {
        CalendarInfo *info = obj;
        CalendarCellView *calendar = [tableView makeViewWithIdentifier:kCalendarCellId owner:self];
        if (!calendar) calendar = [CalendarCellView new];
        calendar.checkbox.target = self;
        calendar.checkbox.action = @selector(calendarClicked:);
        calendar.checkbox.state = info.selected == NSControlStateValueOn;
        calendar.checkbox.tag = row;
        calendar.holidayCheckbox.target = self;
        calendar.holidayCheckbox.action = @selector(holidayClicked:);
        calendar.holidayCheckbox.tag = row;
        calendar.holidayCheckbox.state = [[NSUserDefaults.standardUserDefaults arrayForKey:@"HolidayCalendarIdentifiers"] containsObject:info.calendar.calendarIdentifier] ? NSControlStateValueOn : NSControlStateValueOff;
        [calendar.holidayCheckbox.cell setAccessibilityLabel:[NSString stringWithFormat:@"%@의 일정은 공휴일",info.calendar.title]];
        calendar.checkbox.attributedTitle = [[NSAttributedString alloc] initWithString:info.calendar.title attributes:@{NSForegroundColorAttributeName: info.calendar.color, NSFontAttributeName: [NSFont boldSystemFontOfSize:12]}];
        v = calendar;
    }
    return v;
}

@end

#pragma mark -
#pragma mark Source and Calendar cell views

// =========================================================================
// SourceCellView
// =========================================================================

@implementation SourceCellView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.identifier = kSourceCellId;
        _textField = [NSTextField labelWithString:@""];
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.lineBreakMode = NSLineBreakByWordWrapping;
        _textField.font = [NSFont boldSystemFontOfSize:12];
        _textField.stringValue = @"";
        [self addSubview:_textField];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4-[_textField]-4-|" options:0 metrics:nil views:@{@"_textField": _textField}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[_textField]" options:0 metrics:nil views:@{@"_textField": _textField}]];
    }
    return self;
}

@end

// =========================================================================
// CalendarCellView
// =========================================================================

@implementation CalendarCellView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.identifier = kCalendarCellId;
        _checkbox = [NSButton new];
        _checkbox.translatesAutoresizingMaskIntoConstraints = NO;
        _checkbox.lineBreakMode = NSLineBreakByWordWrapping;
        [_checkbox setButtonType:NSButtonTypeSwitch];
        [self addSubview:_checkbox];
        _holidayCheckbox=[NSButton checkboxWithTitle:@"이 캘린더의 일정은 공휴일" target:nil action:nil];
        _holidayCheckbox.font=[NSFont systemFontOfSize:11];
        _holidayCheckbox.toolTip=@"일정 목록 표시 여부와 관계없이 해당 날짜를 붉은색으로 표시합니다.";
        _holidayCheckbox.translatesAutoresizingMaskIntoConstraints=NO;
        [self addSubview:_holidayCheckbox];
        [NSLayoutConstraint activateConstraints:@[
            [_holidayCheckbox.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24],
            [_holidayCheckbox.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-4],
            [_holidayCheckbox.topAnchor constraintEqualToAnchor:_checkbox.bottomAnchor constant:2]]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4-[_checkbox]-4-|" options:0 metrics:nil views:@{@"_checkbox": _checkbox}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[_checkbox]" options:0 metrics:nil views:@{@"_checkbox": _checkbox}]];
    }
    return self;
}

@end
