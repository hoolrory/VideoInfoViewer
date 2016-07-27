//
//  ObjC.m
//  VideoInfoViewer
//
//  Created by Hool, Rory on 7/22/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

#import "ObjC.h"

#include <iostream>

#import "CPPTest.h"

@implementation ObjC

+ (void) test: (NSString*) test
{
    // std::string *bar = new std::string([test UTF8String]);
    const char *cfilename=[test UTF8String];
    CPPTest::test(cfilename);
}
@end