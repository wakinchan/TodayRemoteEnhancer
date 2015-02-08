//
//  TodayRemoteEnhancer.m
//  TodayRemoteEnhancer
//
//  Created by kinda on 2015/02/08.
//  Copyright (c) 2015 kinda. All rights reserved.
//

// really global volume up/down.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface RPMenulet : NSObject
- (void)processInput:(NSData *)data fromSocket:(id /* GCDAsyncSocket */)socket;
@end

static NSString * const kUser = @"kinda";
static NSString * const kLauncherPath = @"/Applications/IRLauncher.app/Contents/MacOS/IRLauncher";
static NSString * const kJsonPath = @"/Users/%@/.irkit.d/signals/%@.json";

typedef enum {
    VOL_DOWN,
    VOL_UP,
    GLOBAL_VOL_DOWN,
    GLOBAL_VOL_UP,
    RESUME,
    NEXT,
    PREVIEW,
    PG // first connection?
} kInputCmd;
#define kInputCmdArray @"vd", @"vu", @"gvd", @"gvu", @"pp", @"nx", @"pv", @"pg", nil

static NSString * enumToString(kInputCmd val)
{
    NSArray *inputCmdArray = [[NSArray alloc] initWithObjects:kInputCmdArray];
    return [inputCmdArray objectAtIndex:val];
}

static void SendSingnalWithName(NSString *name)
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:kLauncherPath];
    [task setArguments:@[ [NSString stringWithFormat:kJsonPath, kUser, name] ]];
    [task launch];
}

@implementation NSObject (TodayRemoteEnhancer)
- (void)__processInput:(NSData *)data fromSocket:(id /* GCDAsyncSocket */)socket;
{
    // unsigned char *bytePtr = (unsigned char *)[data bytes];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];

    if ([json[@"k"] isEqualToString:@"cmd"]) {
        if ([json[@"cmd"] isEqualToString:enumToString(GLOBAL_VOL_DOWN)]) {
            SendSingnalWithName(@"a_volume down");
            return;
        }
        if ([json[@"cmd"] isEqualToString:enumToString(GLOBAL_VOL_UP)]) {
            SendSingnalWithName(@"a_volume up");
            return;
        }
    }

    [self __processInput:data fromSocket:socket];
}
@end

@interface TodayRemoteEnhancer : NSObject
+ (void)load;
+ (TodayRemoteEnhancer *)sharedInstance;
@end

@implementation TodayRemoteEnhancer
static TodayRemoteEnhancer *tre = nil;
+ (TodayRemoteEnhancer *)sharedInstance
{
    if (!tre) {
        tre = [TodayRemoteEnhancer new];
    }
    return tre;
}

+ (void)load
{
    TodayRemoteEnhancer *tre = [TodayRemoteEnhancer sharedInstance];
    if (tre) {
        method_exchangeImplementations(class_getInstanceMethod(objc_getClass("RPMenulet"), @selector(processInput:fromSocket:)),
                                       class_getInstanceMethod(objc_getClass("NSObject"), @selector(__processInput:fromSocket:)));
    }
}
@end

