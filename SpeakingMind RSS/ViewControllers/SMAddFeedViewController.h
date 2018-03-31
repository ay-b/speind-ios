//
//  SMAddFeedViewController.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 08.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMFeedItem;

/**
 * 
 */
@interface SMAddFeedViewController : UIViewController

/**
 * Перешли для редактирование или добавления нового потока.
 */
@property (nonatomic) BOOL isEditing;

/**
* Если это редактирование, то feed != nil.
*/
@property (nonatomic, weak) SMFeedItem *feed;

@end
