//
//  AcapelaLicense+Speind.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 9/11/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "AcapelaLicense+Speind.h"

@implementation AcapelaLicense (Speind)

+ (instancetype)speindLicense
{
    return [[self alloc] initLicense:[[NSString alloc] initWithCString:"\"3009 0 cPwV #COMMERCIAL#Speaking Mind Russia\"\nT%cKNpOkmEpXFNAQ9CbdpZ4WngYqRst6iHC!CMs9Ec!JbBNEz@elrGNSzG37\nUK5fP8OqnxGXZaPAEks59SByGUlO$4MXgF$P@FbxqqbmHti#\nSi!7AP$h!r4nwVVFqJ4j5T##\n" encoding:NSASCIIStringEncoding] user:0x010ce8a7 passwd:0x0024ed0d];
}

+ (instancetype)evaluationLicense
{
    return [[self alloc] initLicense:[[NSString alloc] initWithCString:"\"5362 0 SIOS #EVALUATION#Acapela Group iOS SDK\"\nVCmvt3MUaXuZYp!bPCcQE$vepAzW2adJnSdebiYsamzm7BYlV3ftfgKZ5nyAuT##\nV6mh7KSc4OayG2p7KqSQbODlimwVE6lFdYFr$YLd2InWvVYW\nY2JTABPAjcyrOb2Qtl5M7R##\n" encoding:NSASCIIStringEncoding] user:0x534f4953 passwd:0x0059c0f3];
}

@end