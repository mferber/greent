//
//  DDLogSwift.h
//  GreenT
//
//  Created by Matthias Ferber on 12/26/14.
//  Copyright (c) 2014 Robot Pie. All rights reserved.
//

// See http://thehustudio.com/taste-of-ios-bridging-cocoalumberjack-for-swift/

#import <Foundation/Foundation.h>

@interface DDLogSwift : NSObject

+ (void) logError:(NSString *)message;
+ (void) logWarn:(NSString *)message;
+ (void) logInfo:(NSString *)message;
+ (void) logDebug:(NSString *)message;
+ (void) logVerbose:(NSString *)message;

@end