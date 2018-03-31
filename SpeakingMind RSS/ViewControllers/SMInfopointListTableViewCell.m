//
//  SMInfopointListTableViewCell.m
//  Speind
//
//  Created by Sergey Butenko on 4/2/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointListTableViewCell.h"
#import "SMInfopoint.h"
#import "NSString+TimeToString.h"

#import <SDWebImage/UIImageView+WebCache.h>

@interface SMInfopointListTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewImageHeight;

@property (weak, nonatomic) IBOutlet UIImageView *providerIconImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sourceIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *providerLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation SMInfopointListTableViewCell

- (void)configureWithInfopoint:(SMInfopoint*)infopoint details:(BOOL)details
{
    self.contentView.backgroundColor = SMGrayColor;
    
    self.dateLabel.text = [NSString stringFromDate:infopoint.pubDate];
    self.providerLabel.text = infopoint.postSender ? infopoint.postSender : @"";
    [self.providerIconImageView sd_setImageWithURL:[NSURL URLWithString:infopoint.senderIcon] placeholderImage:[UIImage imageNamed:@"provider_default"]];
    self.sourceIconImageView.image = infopoint.sourceIcon;
    self.descriptionLabel.text = [infopoint displayingTextForFullArticle:details];
    
    if (!infopoint.enclosure) {
        self.previewImageHeight.constant = 0;
        return;
    }
    
    UIImage *placeholder = [UIImage imageNamed:infopoint.placeholder];
    self.previewImageView.image = placeholder;
    
    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:infopoint.enclosure];
    if (cachedImage) {
        self.previewImageView.image = cachedImage;
    }
    else  {
        [self.previewImageView sd_setImageWithURL:[NSURL URLWithString:infopoint.enclosure] placeholderImage:placeholder options:SDWebImageContinueInBackground completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [[SDImageCache sharedImageCache] storeImage:image forKey:infopoint.enclosure];
        }];
    }
    
    double height = self.previewImageView.bounds.size.width / 2;
    if (details) {
        double e = self.previewImageView.bounds.size.width / self.previewImageView.image.size.width;
        height = e * self.previewImageView.image.size.height;
    }
    self.previewImageHeight.constant = height;
}

@end
