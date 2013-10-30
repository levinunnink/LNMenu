//
//  LNAppDelegate.m
//  LNMenu
//
//  Created by Levi Nunnink on 10/30/13.
//  Copyright (c) 2013 Levi Nunnink. All rights reserved.
//

#import "LNAppDelegate.h"
#import "LNMenu.h"
#import "LNMenuItemView.h"

@interface LNAppDelegate ()

@property (nonatomic, strong) LNMenu *menu;
@property (nonatomic, strong) NSPopover *popover;

@end

@implementation LNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.menu = [LNMenu menu];
    
    LNMenuItemView *test = [LNMenuItemView menuItemViewWithTitle:@"Test" target:self selector:@selector(action:)];
    
    test.mouseHover = ^(LNMenuItemView *owner){
        NSView *view = owner;
        [self.popover close];
        self.popover = [[NSPopover alloc] init];
        self.popover.contentViewController = self.popoverContent;
        
        [self.popover showRelativeToRect:view.bounds ofView:view preferredEdge:NSMinXEdge];
    };
    test.mouseOut = ^(LNMenuItemView *owner){
        [self.popover close];
    };
    
    [self.menu addItem: test];
    [self.menu addItem:[LNMenuItemView menuItemViewWithTitle:@"Quit" target:[NSApplication sharedApplication] selector:@selector(terminate:)]];
}

- (IBAction)showMenu:(id)sender
{
    [self.menu setPostionRelativeToView:sender];
    [self.menu show:sender];
}

- (void)action:(id)sender
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Action!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"To the Batmobile, Robin!"];
    
    [alert runModal];
}

@end
