//
//  ObjC.m
//  VideoInfoViewer
//
//  Created by Hool, Rory on 7/22/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

#import "ObjC.h"

#import "CPPTest.h"

@implementation ObjC

+ (void) test: (NSInteger) test
{
    CPPTest::test((unsigned int)test);
}
@end