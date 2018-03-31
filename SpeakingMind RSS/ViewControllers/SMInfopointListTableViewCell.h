//
//  SMInfopointListTableViewCell.h
//  Speind
//
//  Created by Sergey Butenko on 4/2/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMTableViewCell.h"

@class SMInfopoint;

@interface SMInfopointListTableViewCell : SMTableViewCell

- (void)configureWithInfopoint:(SMInfopoint*)infopoint details:(BOOL)details;

@end
