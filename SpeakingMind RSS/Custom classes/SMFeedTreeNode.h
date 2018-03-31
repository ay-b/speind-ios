
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

#import <Foundation/Foundation.h>
#import "SMFeedItem.h"

/**
 *
 * Объекты этого класса являются узлами в TreeView.
 *
 * Сам объект состоит из названия узла, детей, и источника. Источники содержатся только в листьях дерева.
 *
 */
@interface SMFeedTreeNode : NSObject

/**
 * Заголовок ячейки.
 */
@property (nonatomic, readonly) NSString *name;

/**
 * Вложенные ячейки, которые имеют такой же типа(instancetype).
 */
@property (nonatomic, readonly) NSArray *children;

/**
 * Данные, которые ассоциируются с листом дерева, т.е. если children.count == 0, то feed != nil.
 */
@property (nonatomic, readonly) SMFeedItem *feed;

/**
 * Initializer for a node.
 */
+ (id)dataObjectWithName:(NSString *)name children:(NSArray *)children;

/**
 * Initializer for a leaf.
 */
+ (id)dataObjectWithName:(NSString *)name feed:(SMFeedItem*)feed;

/**
 * Необходимо вызывать, когда мы выбрали все источники для подгруппы, а группы была открыта. Т.е. чтобы отображалось, что все внутренние источники выбраны.
 */
- (void)updateSelection;

/**
 * Является ли этот элемент источником.
 */
- (BOOL)isFeed;

/**
 * Выбрана эта группа или источник.
 */
- (BOOL)isSelected;

/**
 * Выбрать текущий источник. Может быть выбран как лист, так и узел. Когда выбирается узел - нужно обновить детей.
 */
- (void)setSelected:(BOOL)selected;

@end
