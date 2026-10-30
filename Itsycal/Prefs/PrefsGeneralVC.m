//
//  Created by Sanjay Madan on 1/11/17.
//  Copyright © 2017 mowglii.com. All rights reserved.
//

#import "PrefsGeneralVC.h"
#import "SettingsStyle.h"
#import "KoreanShortcutView.h"
#import "Itsycal.h"
#import "MoLoginItem.h"
#import "MoVFLHelper.h"
#import "MASShortcut/Shortcut.h"
#import "Sparkle/SUUpdater.h"

@implementation PrefsGeneralVC
{
    NSButton *_login;
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

    // Checkboxes
    _login = chkbx(NSLocalizedString(@"Launch at login", @""));
    _login.action = @selector(launchAtLogin:);
    NSButton *checkUpdates = chkbx(NSLocalizedString(@"Automatically check for updates", @""));
    NSButton *beepBeep = chkbx(NSLocalizedString(@"Beep beep on the hour", @""));

    // Shortcut label
    NSTextField *shortcutLabel = label(NSLocalizedString(@"Keyboard shortcut", @""));

    // Shortcut view
    MASShortcutView *shortcutView = [KoreanShortcutView new];
    [shortcutView setAssociatedUserDefaultsKey:kKeyboardShortcut withTransformerName:MASDictionaryTransformerName];
    [v addSubview:shortcutView];

    // Window position label
    NSTextField *positionLabel = label(NSLocalizedString(@"Window position:", @""));

    // Window position popup
    NSPopUpButton *positionPopup = [NSPopUpButton new];
    [positionPopup addItemsWithTitles:@[NSLocalizedString(@"Below menu bar icon", @""),
                                        NSLocalizedString(@"Top right of screen", @"")]];
    // The tags will be used to bind the selected window
    // position preference to NSUserDefaults.
    [positionPopup itemAtIndex:0].tag = WindowPositionBelowMenuBarIcon;
    [positionPopup itemAtIndex:1].tag = WindowPositionTopRightOfScreen;
    [positionPopup.cell setAccessibilityTitleUIElement:positionLabel.cell];
    [v addSubview:positionPopup];

    [checkUpdates removeFromSuperview];
    SettingsCard *launch=[SettingsCard new], *behavior=[SettingsCard new];
    [v addSubview:launch]; [v addSubview:behavior];
    NSTextField *launchTitle=[NSTextField labelWithString:@"실행과 알림"];
    NSTextField *behaviorTitle=[NSTextField labelWithString:@"단축키와 창 위치"];
    launchTitle.font=behaviorTitle.font=[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    for(NSView *item in @[launchTitle,_login,beepBeep]) [launch addSubview:item];
    for(NSView *item in @[behaviorTitle,shortcutLabel,shortcutView,positionLabel,positionPopup]) [behavior addSubview:item];
    MoVFLHelper *outer=[[MoVFLHelper alloc] initWithSuperview:v metrics:@{@"m":@24} views:NSDictionaryOfVariableBindings(launch,behavior)];
    [outer :@"H:|-m-[launch]-m-|"]; [outer :@"H:|-m-[behavior]-m-|"];
    [outer :@"V:|-m-[launch]-16-[behavior]-m-|"];
    MoVFLHelper *a=[[MoVFLHelper alloc] initWithSuperview:launch metrics:nil views:NSDictionaryOfVariableBindings(launchTitle,_login,beepBeep)];
    [a :@"V:|-16-[launchTitle]-14-[_login]-10-[beepBeep]-16-|"];
    for(NSString *f in @[@"H:|-16-[launchTitle]-(>=16)-|",@"H:|-16-[_login]-(>=16)-|",@"H:|-16-[beepBeep]-(>=16)-|"]) [a :f];
    MoVFLHelper *b=[[MoVFLHelper alloc] initWithSuperview:behavior metrics:nil views:NSDictionaryOfVariableBindings(behaviorTitle,shortcutLabel,shortcutView,positionLabel,positionPopup)];
    [b :@"V:|-16-[behaviorTitle]-16-[shortcutView(25)]-14-[positionPopup]-16-|"];
    [b :@"H:|-16-[behaviorTitle]-(>=16)-|"];
    [b :@"H:|-16-[shortcutLabel(112)]-12-[shortcutView(>=180)]-16-|" :NSLayoutFormatAlignAllCenterY];
    [b :@"H:|-16-[positionLabel(112)]-12-[positionPopup]-16-|" :NSLayoutFormatAlignAllCenterY];

    // Binding for hourly beep
    [beepBeep bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kBeepBeepOnTheHour] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    // Bindings for window position
    [positionPopup bind:@"selectedTag" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:kWindowPosition] options:@{NSContinuouslyUpdatesValueBindingOption: @(YES)}];

    self.view = v;
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    // The API used to check the login item's state (LSSharedFileList) causes
    // errors for users who have network drives but are not connected to their
    // network (github.com/sfsam/Itsycal/issues/15). Give them an option to
    // disable this check.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDoNotCheckLoginItemStatus] == NO) {
        _login.hidden = NO;
        _login.state = MOIsLoginItemEnabled() ? NSControlStateValueOn : NSControlStateValueOff;
    }
    else {
        _login.hidden = YES;
    }
}

#pragma mark -
#pragma mark Login item

- (void)launchAtLogin:(NSButton *)login
{
    MOEnableLoginItem(login.state == NSControlStateValueOn);
}

@end
