//
//  DDLogSwift.m
//  GreenT
//
//  Created by Matthias Ferber on 12/26/14.
//  Copyright (c) 2014 Robot Pie. All rights reserved.
//

// See http://thehustudio.com/taste-of-ios-bridging-cocoalumberjack-for-swift/

#import "CocoaLumberjackSwift.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_WARN;

@implementation DDLogSwift

+ (void) logError:(NSString *)message {
    DDLogError(message);
}

+ (void) logWarn:(NSString *)message {
    DDLogWarn(message);
}

+ (void) logInfo:(NSString *)message {
    DDLogInfo(message);
}

+ (void) logDebug:(NSString *)message {
    DDLogDebug(message);
}

+ (void) logVerbose:(NSString *)message {
    DDLogInfo(message);
}

@end