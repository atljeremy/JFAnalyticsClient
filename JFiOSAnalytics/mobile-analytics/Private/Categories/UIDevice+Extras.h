//
//  UIDevice+Extras.h
//  coMpanion
//
//  Created by Jeremy Fox on 2/6/14.
//  Copyright (c) 2014 RentPath. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Extras)

+ (NSString*)platform;
+ (NSString*)platformString;
+ (BOOL)isiPhone4Type;
+ (BOOL)isiPad2Type;
+ (NSString*)machineName;
+ (float)softwareVersion;
+ (BOOL)isRetinaDisplay;

@end
