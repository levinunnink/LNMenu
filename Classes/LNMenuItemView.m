//    The MIT License (MIT)
//
//    Copyright (c) 2013 Levi Nunnink
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//    the Software, and to permit persons to whom the Software is furnished to do so,
//    subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
//    Created by Levi Nunnink (@a_band) http://culturezoo.com
//    Copyright (C) Droplr Inc. All Rights Reserved
//

#import "LNMenuItemView.h"
#import "LNMenu.h"

#pragma mark -

@interface LNMenuItemView () <LNMenuItemDrawing> @end

@implementation LNMenuItemView


#pragma mark Creation

- (id)initWithTitle:(NSString*)title target:(id)target selector:(SEL)selector {
    
    self = [self initWithFrame:NSZeroRect];
    
    if (self != nil) {        
        self.title  = title;
        self.target = target;
        _enabled    = YES;
        _selector   = selector;
    }

    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    frame.size.height = MENU_ITEM_HEIGHT;
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setAutoresizingMask:NSViewWidthSizable];
        [self subscribeNotifications];
    }
    
    return self;
}


#pragma mark Destruction

- (void)dealloc
{
    [self unsubscribeNotifications];
}

-(void)removeFromSuperview
{
    [self unsubscribeNotifications];
    [super removeFromSuperview];
}

#pragma mark Public static methods

+ (id)menuItemViewWithTitle:(NSString*)title target:(id)target selector:(SEL)selector
{
    return [[LNMenuItemView alloc] initWithTitle:title target:target selector:selector];
}

#pragma mark NSResponder

- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES;
}

#pragma mark NSView

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [self subscribeNotifications];
    self.frame = NSMakeRect(0, self.frame.origin.y, newSuperview.frame.size.width, MENU_ITEM_HEIGHT);
    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kSimulatedMenuItemHighlightedNotification object:self];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kSimulatedMenuMouseHoverNotification object:nil];
    
    [LNMenu cancelPreviousPerformRequestsWithTarget:[self owner]];
    
    _highlighted = YES;
    
    [self setNeedsDisplay:YES];
    
    if (self.mouseHover != nil) {
        self.mouseHover(self);
    }
    
}

- (void)mouseUp:(NSEvent*)theEvent
{
    [self fire:YES];
    
    if (self.mouseUp != nil) {
        self.mouseUp(self);
    }
}

-(void)rightMouseUp:(NSEvent *)theEvent 
{
    [self fire:YES];
    
    if (self.mouseUp != nil) {
        self.mouseUp(self);
    }
}

- (void)mouseExited:(NSEvent*)theEvent
{
    _highlighted = NO;
    [self setNeedsDisplay:YES];
    
    if (self.mouseOut != nil) {
        self.mouseOut(self);
    }
}

-(void)drawRect:(NSRect)dirtyRect
{
    if (_highlighted && [self enabled]) {
        NSImage* bgImage = [[[NSColor selectedMenuItemColor]
                             colorUsingColorSpaceName: @"NSPatternColorSpace"]
                            patternImage];
        NSRect rect = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, bgImage.size.width, bgImage.size.height);
        [bgImage drawInRect:self.bounds fromRect:rect operation:NSCompositeCopy fraction:1.0];
    }

    NSColor* textColor = [self enabled] ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont systemFontOfSize:14], NSFontAttributeName,
                                (_highlighted && [self enabled] ? [NSColor highlightColor] : textColor), NSForegroundColorAttributeName,
                                nil];
    
    NSString *title = self.title;
    
    if ([NSApp currentEvent].modifierFlags & NSAlternateKeyMask && self.altTitle && self.altEnabled) {
        title = self.altTitle;
    }
    
    [title drawAtPoint:NSMakePoint(21, 1) withAttributes:attributes];
    
    NSString *shortcut = self.shortcut;
    
    if ([NSApp currentEvent].modifierFlags & NSAlternateKeyMask && self.altShortcut && self.altEnabled) {
        shortcut = self.altShortcut;
    }
    
    if (shortcut) {
        NSSize shortcutSize = [shortcut sizeWithAttributes:attributes];
        [shortcut drawAtPoint:NSMakePoint(self.frame.size.width-shortcutSize.width-12, 1) withAttributes:attributes];
    }
    
    [super drawRect:dirtyRect];
    
}


#pragma mark LNMenuItemDrawing

- (void)redrawIfNeeded:(NSNotification*)sender
{
    if (![sender.object isEqual:self] && self.superview) {
        _highlighted = NO;
        [self setNeedsDisplay:YES];
    }
}

-(void)fire:(BOOL)animate
{
    _highlighted = NO;
    [self setNeedsDisplay:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.08 target:self selector:@selector(afterFire:) userInfo:nil repeats:NO];
}

#pragma mark Private helpers

- (void)subscribeNotifications
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(redrawIfNeeded:)
     name:kSimulatedMenuItemHighlightedNotification object:nil];
    
}

- (void)unsubscribeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(LNMenu*)owner
{
    return (LNMenu*)[self window];
}

- (void)afterFire:(NSTimer*)timer
{
    _highlighted = YES;
    [self setNeedsDisplay:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL fireSelector = self.selector;
    if ([NSApp currentEvent].modifierFlags & NSAlternateKeyMask && self.altSelector && self.altEnabled) {
        fireSelector = self.altSelector;
    }
    [_target performSelector:fireSelector withObject:self];
#pragma clang diagnostic pop
    [[self owner] hide:self];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.08 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _highlighted = NO;
        [self setNeedsDisplay:YES];
    });
}

@end
