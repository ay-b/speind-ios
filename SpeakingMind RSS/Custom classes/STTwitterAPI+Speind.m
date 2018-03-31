//
//  STTwitterAPI+Speind.m
//  Speind
//
//  Created by Sergey Butenko on 3/10/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "STTwitterAPI+Speind.h"

@implementation STTwitterAPI (Speind)

+ (BOOL)sm_handleTwitterOpenURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication
{
    NSDictionary *info = [self p_parametersDictionaryFromQueryString:[url query]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SMTwitterAuthNotification object:nil userInfo:info];
    return YES;
}

+ (NSDictionary *)p_parametersDictionaryFromQueryString:(NSString *)queryString
{
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *parameter in queryComponents) {
        NSArray *pair = [parameter componentsSeparatedByString:@"="];
        if([pair count] != 2) continue;
        
        NSString *key = pair[0];
        NSString *value = pair[1];
        md[key] = value;
    }
    return md;
}

@end
