//
//  CBCentralHandler.m
//  asu-app
//
//  Created by ArchGryphon9362 on 07/01/2024.
//

#import <Foundation/Foundation.h>
#import "CBCentralManagerHandler.h"
#import "CBCentralManager.h"

@implementation CBCentralManagerHandler

static CBCentralManager *_supporter = nil;
static CBCentralManagerHandler *_handler = nil;

+ (id) retrieveAddressForPeripheral: (id) arg0
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/CoreBluetooth.framework"];
        if (![bundle load]) {
            NSLog(@"Failed to load framework");
        } else {
            _supporter = [NSClassFromString(@"FTDeviceSupport")
                                     valueForKey:@"sharedInstance"];
            _handler = [[CBCentralManagerHandler alloc] init];
        }
    });
    return _handler;
}

@end
