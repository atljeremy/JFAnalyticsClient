//
//  PRMDeviceManager.m
//  ios_primedia
//
//  Created by Jeremy Fox on 9/6/12.
//
//

#import "JFDeviceManager.h"
#import "UIDevice+IdentifierAddition.h"

@implementation JFDeviceManager

+ (NSString*)getUniqueDeviceIdentifier {
    NSString* identifier;
    if (IS_IOS7_OR_GREATER) {
        identifier = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    } else {
        identifier = [[UIDevice currentDevice] uniqueDeviceIdentifier];
    }
    return identifier;
}

@end
