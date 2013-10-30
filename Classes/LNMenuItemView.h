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

#pragma mark -

@class LNMenuItemView;

typedef void (^LNMenuItemMouseEvent)(LNMenuItemView *owner);

@interface LNMenuItemView : NSView

#pragma mark Public properties

@property (nonatomic, strong) id         representedObject;
@property (nonatomic, assign)   id         target;
@property (nonatomic, strong) NSString*  title;
@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic, assign) BOOL       enabled;
@property (nonatomic, assign) BOOL       altEnabled;
@property (nonatomic, strong) NSString*  shortcut;
@property (nonatomic, strong) NSString*  altShortcut;
@property (nonatomic, assign) BOOL       highlighted;
@property (nonatomic, strong) NSString*  altTitle;
@property (nonatomic, assign) SEL        selector;
@property (nonatomic, assign) SEL        altSelector;

@property (nonatomic, strong) LNMenuItemMouseEvent mouseHover;
@property (nonatomic, strong) LNMenuItemMouseEvent mouseOut;
@property (nonatomic, strong) LNMenuItemMouseEvent mouseUp;

#pragma mark Creation

- (id)initWithTitle:(NSString*)title target:(id)target selector:(SEL)selector;


#pragma mark Public static methods

+ (id)menuItemViewWithTitle:(NSString*)title target:(id)target selector:(SEL)selector;

@end
