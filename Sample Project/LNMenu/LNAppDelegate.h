//
//  LNAppDelegate.h
//  LNMenu
//
//  Created by Levi Nunnink on 10/30/13.
//  Copyright (c) 2013 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LNAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSViewController *popoverContent;

- (IBAction)showMenu:(id)sender;

@end
