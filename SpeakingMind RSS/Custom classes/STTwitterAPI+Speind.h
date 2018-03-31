//
//  STTwitterAPI+Speind.h
//  Speind
//
//  Created by Sergey Butenko on 3/10/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "STTwitterAPI.h"

@interface STTwitterAPI (Speind)

+ (BOOL)sm_handleTwitterOpenURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication;

@end
