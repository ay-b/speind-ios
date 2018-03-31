//
//  AcapelaLicense+Speind.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 9/11/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "AcapelaLicense.h"

/**
 * Encapsulates work with licenses for Acapela Speech.
 */
@interface AcapelaLicense (Speind)

/**
 * Speaking Mind commercial licence.
 */
+ (instancetype)speindLicense;

/**
 * License for demo. With an evaluation license, an evaluation message will be played each 400 characters, and a graphical popup will be displayed when you init an AcapelaSpeech instance.
 */
+ (instancetype)evaluationLicense;

@end
