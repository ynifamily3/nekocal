//
//  Created by Sanjay Madan on 1/11/17.
//  Copyright © 2017 mowglii.com. All rights reserved.
//

#import "PrefsAboutVC.h"
#import "MoVFLHelper.h"

@implementation PrefsAboutVC

- (void)loadView
{
    NSView *view = [NSView new];
    NSView *content = [NSView new];
    [view addSubview:content];

    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSTextField *title = [NSTextField labelWithString:info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"] ?: @"KawaiiCal"];
    title.font = [NSFont systemFontOfSize:22 weight:NSFontWeightSemibold];
    NSTextField *version = [NSTextField labelWithString:[NSString stringWithFormat:@"%@ (%@)", info[@"CFBundleShortVersionString"] ?: @"—", info[@"CFBundleVersion"] ?: @"—"]];
    version.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    version.textColor = NSColor.secondaryLabelColor;
    [content addSubview:title];
    [content addSubview:version];

    MoVFLHelper *inner = [[MoVFLHelper alloc] initWithSuperview:content metrics:nil views:NSDictionaryOfVariableBindings(title, version)];
    [inner :@"V:|[title]-8-[version]|"];
    [inner :@"H:|[title]|"];
    [inner :@"H:|-(>=0)-[version]-(>=0)-|"];
    [version.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;

    MoVFLHelper *outer = [[MoVFLHelper alloc] initWithSuperview:view metrics:nil views:NSDictionaryOfVariableBindings(content)];
    [outer :@"V:|-40-[content]-40-|"];
    [outer :@"H:|-(>=24)-[content]-(>=24)-|"];
    [content.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    self.view = view;
}

@end
