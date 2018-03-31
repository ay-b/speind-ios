
//The MIT License (MIT)
//
//Copyright (c) 2013 Rafał Augustyniak
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of
//this software and associated documentation files (the "Software"), to deal in
//the Software without restriction, including without limitation the rights to
//use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//the Software, and to permit persons to whom the Software is furnished to do so,
//subject to the following conditions:
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SMFeedTreeNode.h"

@interface SMFeedTreeNode()
{
    BOOL _selected;
}

/**
 * Designated initializer.
 */
- (id)initWithName:(NSString *)name children:(NSArray *)children feed:(SMFeedItem*)feed NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSArray *children;
@property (nonatomic, readwrite) SMFeedItem *feed;

@end

@implementation SMFeedTreeNode

#pragma mark - Init
#pragma mark Base

- (id)initWithName:(NSString *)name children:(NSArray *)children feed:(SMFeedItem*)feed
{
    self = [super init];
    if (self) {
        self.children = children;
        self.name = name;
        self.feed = feed;
        [self updateSelection];
    }
    return self;
}

#pragma mark Other

+ (id)dataObjectWithName:(NSString *)name children:(NSArray *)children
{
    return [[self alloc] initWithName:name children:children feed:nil];
}

+ (id)dataObjectWithName:(NSString *)name feed:(SMFeedItem*)feed
{
    return [[self alloc]initWithName:name children:nil feed:feed];
}

#pragma mark -

- (BOOL)shouldBeSelected
{
    BOOL newSelection = NO;
    
    if (_children.count > 0) {
        for (SMFeedTreeNode *сhild in _children) {
            [сhild updateSelection];
            if ([сhild shouldBeSelected]) {
                newSelection = YES;
            }
        }
    }
    else {
        newSelection = self.isSelected;
    }
    
    return newSelection;
}

- (void)updateSelection
{
    self.selected = [self shouldBeSelected];
}

- (BOOL)isFeed
{
    return _children.count == 0;
}

- (BOOL)isSelected
{
    return _selected || _feed.isSelected;
}

- (void)setSelected:(BOOL)selected
{
    self.feed.selected = selected;
    _selected = selected;
}

- (NSString *)description
{
    return _name;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    else if ([other isKindOfClass:[SMFeedTreeNode class]]) {
        SMFeedTreeNode *node = other;
        return [_name isEqualToString:node.name] && [_children isEqualToArray:node.children];
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return [_name hash] + [_children hash];
}

@end
