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

#import "LNMenu.h"
#import "LNMenuItemView.h"

#pragma mark - Constants

#define MENU_BOTTOM_PAD 5
#define kPositioningViewKey @"kPositioningViewKey"


#pragma mark Private method signature


@interface LNMenuView()

#pragma mark Private helpers

- (void)removeTrackingAreas;

- (void)layout; //backwards compatibility for < 10.7

@end



#pragma mark -

@interface LNMenuSeparator : NSView <LNMenuItemDrawing>
{
    NSInteger _tag;
}

@property(nonatomic, assign) NSInteger tag;

@end



#pragma mark -

@interface LNMenu () <NSPopoverDelegate ,NSAnimationDelegate>


#pragma mark Private properties

@property (nonatomic, strong) LNMenuView* view;
@property (nonatomic, strong) NSView* positioningView;
@property (nonatomic, strong) NSString* currentSearchString;
@property (nonatomic, strong) NSString* lastSelectedLetter;
@property (nonatomic, strong) NSTimer*  trackPopoverTimer;
@property (nonatomic, assign) BOOL isResigningKey;
@property (nonatomic, assign) BOOL trackPopover;
@property (nonatomic, assign) BOOL trackingMouse;
@property (nonatomic, assign) NSTimer* stringResetTimer;
@property (nonatomic, assign) NSView* selectedView;

@end



#pragma mark -

@implementation LNMenu

#pragma mark Creation

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:NSZeroRect styleMask:NSNonactivatingPanelMask
                              backing:NSBackingStoreBuffered defer:NO];
    
    [self setFrame:NSMakeRect(0, 0, 300, 208) display:NO];
    [self setFloatingPanel:YES];
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    [self setBackgroundColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.0]];
    [self setMovableByWindowBackground:NO];
    [self setExcludedFromWindowsMenu:YES];
    [self setAlphaValue:0.0];
    [self setOpaque:NO];
    self.delegate = self;
    [self setHasShadow:YES];
    [self useOptimizedDrawing:YES];
    [self setHidesOnDeactivate:NO];
    [self setLevel:kCGMaximumWindowLevel];
    self.view = [[LNMenuView alloc] initWithFrame:NSMakeRect(0, 0, 300, 208)];
    [self setContentView:self.view];
    [self setRestorable:NO];
    [self disableSnapshotRestoration];

    //set the selected index to -1 instead of zero
    _selectedIndex = -1;
    self.currentSearchString = @"";
    _trackPopover = NO;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(hidePopoverIfNeeded:)
     name:kSimulatedMenuItemHighlightedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(startTrackingMouse)
     name:kSimulatedMenuMouseHoverNotification object:nil];
    
    return self;
}

- (void)empty
{
    [self.view setSubviews:[NSArray array]];
}

#pragma mark overrride 

- (NSString*)description
{
    NSString* d = [super description];
    for (NSView *v in [self.contentView subviews]) {
        d = [d stringByAppendingFormat:@"\n ---- %@ Frame: %@",v,NSStringFromRect(v.frame)];
    }
    return d;
}

#pragma mark Public static methods

+ (LNMenu*)menu
{
    LNMenu* instance = [[LNMenu alloc]
                      initWithContentRect:NSZeroRect styleMask: NSBorderlessWindowMask
                      backing:NSBackingStoreBuffered defer:NO];

    return instance;
}

+ (NSView*)separatorItem
{
    return [[LNMenuSeparator alloc] initWithFrame:NSMakeRect(0, 0, 0, SEPARATOR_ITEM_HEIGHT)];
}

+ (NSView*)separatorItemWithTag:(NSInteger)tag
{
    LNMenuSeparator* separator = [[LNMenuSeparator alloc]
                                          initWithFrame:NSMakeRect(0, 0, 0, SEPARATOR_ITEM_HEIGHT)];
    separator.tag = tag;
    return separator;
}


#pragma mark NSPanel

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

#pragma Public methods

- (void)show:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSimulatedMenuWillOpenNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSimulatedMenuItemHighlightedNotification object:nil];

    if ([self.menuDelegate respondsToSelector:@selector(LNMenuWillOpen:)]) {
        [self.menuDelegate LNMenuWillOpen:self];
    }
    
    [self setPostionRelativeToView:sender];
    
    [self setAlphaValue:1.0];
    [self setIsVisible:YES];
    [self.view updateTrackingAreas];
    [self becomeKeyWindow];

}

- (void)hide:(id)sender
{
    if (!self.isVisible || self.alphaValue == 0.0) {
        return;
    }
    
    if (self.isKeyWindow && !_isResigningKey) {
        _isResigningKey = YES;
        [LNMenu cancelPreviousPerformRequestsWithTarget:self];
        [self resignKeyWindow];
        return;
    }
    if (_isResigningKey) {
        _isResigningKey = NO;
    }
    
    _selectedIndex = -1; //reset our selected index
        
    NSMutableArray *animations = [NSMutableArray array];
    
    NSDictionary *fadeOut = [NSDictionary dictionaryWithObjectsAndKeys: self, NSViewAnimationTargetKey,NSViewAnimationFadeOutEffect,NSViewAnimationEffectKey, nil];
    [animations addObject:fadeOut];
    
    NSViewAnimation *animation;
    animation = [[NSViewAnimation alloc] initWithViewAnimations: animations];
    [animation setDuration: 0.2];
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setDelegate:self];
    [animation startAnimation];
    
    [self removeHighlights];
    
}

- (void)setPostionRelativeToView:(NSView*)view
{
    NSRect frame  = [[view window] convertRectToScreen:view.frame];
    
    NSPoint point = frame.origin;

    if ((point.x + self.frame.size.width) > [NSScreen mainScreen].frame.size.width) {
        point.x = point.x - self.frame.size.width + view.frame.size.width;
    }
    
    NSRect newFrame = NSMakeRect(point.x, point.y - self.frame.size.height,
                                 self.frame.size.width, self.frame.size.height);
    [self setFrame:newFrame display:YES];
    self.positioningView = view;
}

- (void)insertItem:(NSView*)view atIndex:(NSInteger)index
{
    NSMutableArray* items = [NSMutableArray array];
    
    float y = MENU_BOTTOM_PAD;
    
    for (int i = 0; i < [self.view.subviews count]; i++) {
        NSView* v = [self.view.subviews objectAtIndex:i];
        NSRect frame = v.frame;
        frame.origin.y = y;
        v.frame = frame;
        if (i == index) {
            NSRect newFrame = view.frame;
            newFrame.origin.y = y;
            view.frame = newFrame;
            [items addObject:view];
            y += view.frame.size.height;
            frame.origin.y = y;
            v.frame =frame;
        }
        [items addObject:v];
        y += v.frame.size.height;
    }
    [self.view setSubviews:items];
    [self sizeToFit];
}

- (void)addItem:(NSView*)item
{
    NSRect viewFrame = item.frame;
    viewFrame.origin.y = MENU_BOTTOM_PAD;
    for(NSView *v in [self.view subviews]){
        viewFrame.origin.y+=v.frame.size.height;
    }
    item.frame = viewFrame;
    [self.view addSubview:item];
    [self sizeToFit];
}

- (NSView*)itemAtIndex:(NSUInteger)index
{
    return [[self.view subviews] objectAtIndex:index];
}

- (NSView*)itemWithTag:(NSInteger)tag
{
    return [self.view viewWithTag:tag];
}

- (NSArray*)itemsWithTag:(NSInteger)tag
{
    NSMutableArray* views = [NSMutableArray array];
    for (NSView* subview in self.view.subviews) {
        if (subview.tag == tag) {
            [views addObject:subview];
        }
    }
    
    return views;
}

- (BOOL)removeItemsWithTag:(NSInteger)tag
{
    // Can't mutate while traversing, so we collect the ones to keep
    NSMutableArray* itemsToKeep = [NSMutableArray array];
    for (NSView* v in self.view.subviews) {
        if (v.tag != tag) {
            [itemsToKeep addObject:v];
        }
    }

    // Small optimization; if no items were discarded, then don't change the subviews
    if (self.view.subviews.count == itemsToKeep.count) {
        return NO;
    }

    // Items were removed, update the view
    self.view.subviews = itemsToKeep;

    [self.view layout];
    [self sizeToFit];

    return YES;
}

- (BOOL)removeItemsWithTagAnimated:(NSInteger)tag
{
    // Can't mutate while traversing, so we collect the ones to keep
    NSMutableArray* itemsToKeep = [NSMutableArray array];
    NSInteger moveUp = 0;
    for (NSView* v in self.view.subviews) {
        if (v.tag != tag) {
            [itemsToKeep addObject:v];
            if (moveUp != 0) {
                [[v animator] setFrameOrigin:NSMakePoint(v.frame.origin.x, v.frame.origin.y + moveUp)];
            }
        } else {
            moveUp -= v.frame.size.height;
            [[v animator] setFrameSize:NSMakeSize(v.frame.size.width, 0)];
        }
    }
    
    // Small optimization; if no items were discarded, then don't change the subviews
    if (self.view.subviews.count == itemsToKeep.count) {
        return NO;
    }
    
    // Items were removed, update the view
    [self keepSubviews:itemsToKeep];
    
    // Super hack to the rescue :D
    [self.view layout];
    [self sizeToFitWithSubviews:itemsToKeep];
    
    return YES;
}

- (void)keepSubviews:(NSArray*)subviews
{
    self.view.subviews = subviews;
}

- (void)removeItemAtIndex:(NSUInteger)index
{
    //Make sure we don't track anything on this item anymore
    [[[self.view subviews] objectAtIndex:index] removeFromSuperview];
}

- (void)removeItem:(NSView*)item
{
    [item removeFromSuperview];
    [self.view layout];
    [self sizeToFit];
}

- (void)removeHighlights
{
    for (id view in self.view.subviews) {
        if ([view isKindOfClass:[LNMenuItemView class]]) {
            [view setHighlighted:NO];
        }
    }
}

- (NSUInteger)numberOfItems
{
    return [[self.view subviews] count];
}

- (NSUInteger)indexOfItem:(NSView*)item
{
    
    int i = 0;
    
    for(NSView *v in [self.view subviews]){
        if([v isEqual:item]){
            return i;
        }
        i++;
    }
    
    return -1;
}

- (NSArray*)itemArray
{
    return [self.view subviews];
}

#pragma mark NSAnimationDelegate

- (void)animationDidEnd:(NSAnimation *)_animation
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSimulatedMenuWillCloseNotification object:nil];
    
    [self.menuDelegate LNMenuWillClose:self];
    [self setIsVisible:NO];
    [self.view removeTrackingAreas];
}


#pragma NSWindow delegate methods

- (void)windowDidResignKey:(NSNotification *)notification
{
    [self hide:notification];
}


#pragma mark Private helpers

- (void)sizeToFit
{
    [self sizeToFitWithSubviews:self.view.subviews];
}

- (void)sizeToFitWithSubviews:(NSArray*)subviews
{
    NSRect frame = self.frame;
    float newHeight = MENU_BOTTOM_PAD;
    
    for (NSView* v in subviews) {
        newHeight += v.frame.size.height;
        [v setNeedsDisplay:YES];
    }
    
    newHeight += MENU_BOTTOM_PAD;
    frame.origin.y += self.frame.size.height - newHeight;
    frame.size.height = newHeight;
    
    [[self animator] setFrame:frame display:YES];
    [self setPostionRelativeToView:self.positioningView];
    [self.view updateTrackingAreas];
}

- (void)hidePopoverIfNeeded:(NSNotification*)sender
{
    if(_trackingMouse){ //Only do this if we're navigating by mouse
        int i = 0;
        for(id v in [[self contentView] subviews]){
            if ([v isEqual:sender.object]) {
                //We need to set this so if we switch to key navigation, we're at the right index
                _selectedIndex = i;
                break;
            }
            i++;
        }
    }
}

- (void)resetSearchString {
    self.currentSearchString = @"";
}
     
- (void)beginTrackingPopover {
    _trackPopover = YES;
}

- (void)stopTrackingPopover {
    if ([self.trackPopoverTimer isValid]) {
        [self.trackPopoverTimer invalidate];
    }
    _trackPopover = NO;
}

- (void)startTrackingMouse {
    _trackingMouse = YES;
}

#pragma mark Responder methods

- (void)keyDown:(NSEvent *)theEvent {
    
    //We're navigating by keys, don't track mouse events
    _trackingMouse = NO;
    
    NSString *characters;
    characters = [theEvent characters];
    
    unichar character;
    character = [characters characterAtIndex: 0];
    
    if (character == NSDownArrowFunctionKey) {
        _selectedIndex += 1;
        //Need to check our view to make sure it can be highlighted
        NSView *v = [[[self contentView] subviews] objectAtIndex:_selectedIndex];
        if (([v isKindOfClass:[LNMenuItemView class]] && ![(LNMenuItemView*)v enabled]) ||
            [v isKindOfClass:[LNMenuSeparator class]]) {
            //If the view is a kind of class that cannot be highlighted, skip it and run the function agin
            [self keyDown:theEvent];
            return;
        }
        [self setSelectedIndex: _selectedIndex];

        
    } else if (character == NSUpArrowFunctionKey) {
        if (self.selectedIndex != -1) {
            _selectedIndex -= 1;
            //Need to check our view to make sure it can be highlighted
            NSView *v = [[[self contentView] subviews] objectAtIndex:_selectedIndex];
            if (([v isKindOfClass:[LNMenuItemView class]] && ![(LNMenuItemView*)v enabled]) ||
                [v isKindOfClass:[LNMenuSeparator class]]) {
                //If the view is a kind of class that cannot be highlighted, skip it and run the function agin
                [self keyDown:theEvent];
                return;
            }
            [self setSelectedIndex: _selectedIndex];
        }
        
    } else if ([theEvent keyCode] == 53) { //esc
        //Un-highlight the selected item
        if (_selectedIndex >= 0 && [[self itemAtIndex:_selectedIndex] respondsToSelector:@selector(setHighlighted:)]) {
            [(id)[self itemAtIndex:_selectedIndex] setHighlighted:NO];
        }
        [self resignFirstResponder];
        [self resignKeyWindow];
    } else if (character == NSCarriageReturnCharacter){ //return
        if ([_selectedView respondsToSelector:@selector(fire:)]) {
            [_selectedView performSelector:@selector(fire:)];
        }
    }
}

- (void)keyUp:(NSEvent *)theEvent {
    NSString *characters;
    characters = [theEvent characters];
    unichar character;
    character = [characters characterAtIndex: 0];
    if (character != NSDownArrowFunctionKey &&
        character != NSUpArrowFunctionKey) {
        self.currentSearchString = [self.currentSearchString stringByAppendingString:[theEvent characters]];
        
        if ([_stringResetTimer isValid]) {
            [_stringResetTimer invalidate]; //reset our timer so it only starts from the last keyup 
        }
        _stringResetTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(resetSearchString) userInfo:nil repeats:NO];
        [self highlightItemWithString: self.currentSearchString];
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    int i = 0;
    id selectedView = nil;
    for (id v in [self.view subviews]) {
        if (![v isKindOfClass:[LNMenuSeparator class]]) {
            if (i==selectedIndex) {
                [v setHighlighted:YES];
                [v setNeedsDisplay:YES];
                selectedView = v;
            }else{
                [v setHighlighted:NO];
            }
        }
        i++;
        if (selectedView) {
            _selectedView = selectedView;
            [selectedView setHighlighted:YES];
            [selectedView setNeedsDisplay:YES];
        }
        [v setNeedsDisplay:YES];
    }
}

- (void)highlightItemWithString:(NSString*)string {
    
    BOOL foundView = NO;
    NSUInteger i = 0;
    NSUInteger selectIndex = _selectedIndex;
    
    for (id v in [self.view subviews]) {
        if ([v isKindOfClass:[LNMenuItemView class]]) {
            if ([v isKindOfClass:[LNMenuItemView class]]) {
                foundView = [[[(LNMenuItemView*)v title] lowercaseString] hasPrefix:[string lowercaseString]];
            }
            if (foundView) {
                if([string isEqualToString:self.lastSelectedLetter]){
                    if (i < _selectedIndex) {
                        selectIndex = i; //only set if not equal
                    }
                }else {
                    selectIndex = i;
                }
                
            }
        }
        if (![v isKindOfClass:[LNMenuSeparator class]]) {
            i++; //we don't increment simlulated menu separators
        }
    }
    
    if (selectIndex != _selectedIndex) {
        self.lastSelectedLetter = string;
        [self setSelectedIndex:selectIndex];
    }
}

@end



#pragma mark -

@implementation LNMenuView

- (void)removeTrackingAreas
{
    for (NSTrackingArea* ta in [self trackingAreas]) {
        [self removeTrackingArea:ta];
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    for (NSTrackingArea* ta in [self trackingAreas]) {
        [self removeTrackingArea:ta];
    }
    
    if ([[self window] isVisible]) {    
        for (NSView* v in self.subviews) {
            NSTrackingArea* track = [[NSTrackingArea alloc]
                                      initWithRect:v.frame
                                      options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways)
                                      owner:v userInfo:nil];
            [self addTrackingArea:track];
        }
    }
}

- (void)layout
{
    
    [super layout];
    
    float y = MENU_BOTTOM_PAD;
    
    for (int i = 0; i < [[self subviews] count]; i++){
        NSView *v = [[self subviews] objectAtIndex:i];
        NSRect frame = v.frame;
        frame.origin.y = y;
        v.frame = frame;
        y+=frame.size.height;
    }
    
}

- (id)initWithFrame:(NSRect)frameRect
{

    self = [super initWithFrame:frameRect];
    [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [self setAutoresizesSubviews:YES];
    return self;

}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.95] set];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    NSBezierPath *clip = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4 yRadius:4];
    [clip setClip];
    
    NSRectFill(dirtyRect);
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

@end



#pragma mark -

@implementation LNMenuSeparator

#pragma mark - Delegate methods

- (void)redrawIfNeeded:(NSNotification*)sender
{
    if (![[sender object] isEqual:self]) {
        [self setNeedsDisplay:YES];
    }
}

- (void)fireIfContainsPoint:(NSNotification *)sender
{
    //we never fire a separator item
    return;
}

- (void)activateIfContainsPoint:(NSNotification *)sender
{
    [self setNeedsDisplay:YES];
}

#pragma -

- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self setNeedsDisplay:YES];
    [LNMenu cancelPreviousPerformRequestsWithTarget:[self window]];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self setNeedsDisplay:YES];    
}

- (void)viewDidMoveToSuperview
{
    self.frame = NSMakeRect(0, self.frame.origin.y, self.superview.frame.size.width, 11);
    [self setNeedsDisplay:YES];
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    [self setAutoresizingMask:NSViewWidthSizable];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redrawIfNeeded:) name:kSimulatedMenuItemHighlightedNotification object:nil];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor secondarySelectedControlColor] set];
    NSRectFill(NSMakeRect(0, 6, dirtyRect.size.width, 1));
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
