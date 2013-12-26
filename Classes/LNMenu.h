//  The MIT License (MIT)
//
//  Copyright (c) 2013 Levi Nunnink
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
//  Created by Levi Nunnink (@a_band) http://culturezoo.com
//  Copyright (C) Droplr Inc. All Rights Reserved
//

@class LNMenuView;
@class LNMenu;

#pragma mark - Constants

#define MENU_ITEM_HEIGHT       19
#define SEPARATOR_ITEM_HEIGHT  11

#define kSimulatedMenuItemHighlightedNotification @"kSimulatedMenuItemHighlighted"
#define kSimulatedMenuWillCloseNotification @"kSimulatedMenuWillCloseNotification"
#define kSimulatedMenuWillOpenNotification @"kSimulatedMenuWillOpenNotification"
#define kSimulatedMenuMouseHoverNotification @"kSimulatedMenuMouseHoverNotification"



#pragma mark - Protocols

@protocol LNMenuItemDrawing <NSObject>

-(void)redrawIfNeeded:(NSNotification*)sender;
@optional
-(void)fire:(BOOL)animate;

@end


@protocol LNMenuDelegate <NSObject>

-(void)LNMenuWillOpen:(LNMenu*)menu;
-(void)LNMenuWillClose:(LNMenu*)menu;

@end



#pragma mark -

@interface LNMenu : NSPanel <NSWindowDelegate>

#pragma mark Public properties

@property (nonatomic, assign) id<LNMenuDelegate> menuDelegate;
@property (nonatomic, assign) NSInteger          selectedIndex;

#pragma mark Public static methods

+ (LNMenu*)menu;
+ (NSView*)separatorItem;
+ (NSView*)separatorItemWithTag:(NSInteger)tag;


#pragma mark Public methods

- (void)show:(id)sender;
- (void)hide:(id)sender;
- (void)setPostionRelativeToView:(NSView*)view;
- (void)insertItem:(NSView*)view atIndex:(NSInteger)index;
- (void)addItem:(NSView*)item;
- (NSView*)itemAtIndex:(NSUInteger)index;
- (NSView*)itemWithTag:(NSInteger)tag;
- (NSArray*)itemsWithTag:(NSInteger)tag;
- (BOOL)removeItemsWithTag:(NSInteger)tag;
- (void)removeItemAtIndex:(NSUInteger)index;
- (void)removeItem:(NSView*)item;
- (NSUInteger)numberOfItems;
- (NSUInteger)indexOfItem:(NSView*)item;
- (NSArray*)itemArray;
- (void)empty;

@end



#pragma mark -

@interface LNMenuView : NSView

#pragma mark Public properties

@property(nonatomic, retain) NSPopover* popover;

@end
