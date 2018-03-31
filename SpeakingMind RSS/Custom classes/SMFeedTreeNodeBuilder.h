//
//  SMFeedTreeNodeBuilder.h
//  Speind
//
//  Created by Sergey Butenko on 25.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMFeedTreeNodeBuilder : NSObject

+ (instancetype)sharedBuilder;

/**
 *
 * Берет данные из базы и компонует из них SMFeedTreeNode для отображения в RATreeView.
 *
 * @param lang Язык, для которого необходимо выбрать источники. Язык задается в короткой форме локали, т.е. "ru", "en", "fr" и т.д.
 * @param country Страна, для которой необходимо выбрать источники.
 *
 *
 * @return Массив объектов SMFeedTreeNode.
 *
 */
- (NSArray*)feedForLang:(NSString*)lang country:(NSString*)country;

@end
