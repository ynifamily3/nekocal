//
//  ItsycalWindow.h
//  Itsycal
//
//  Created by Sanjay Madan on 12/14/14.
//  Copyright (c) 2014 mowglii.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ItsycalWindow : NSPanel

- (void)positionRelativeToRect:(NSRect)rect screenMaxX:(CGFloat)screenMaxX;

// Shows the window growing out of its arrow, like NSPopover.
// Falls back to a fade when Reduce Motion is on.
- (void)makeKeyAndOrderFrontAnimated;

@end
