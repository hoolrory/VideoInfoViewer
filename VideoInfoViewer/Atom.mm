//
//  Test.m
//  VideoInfoViewer
//
//  Created by Hool, Rory on 8/9/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Atom.h"
#import "AtomWrapper.h"

@implementation Atom

- init {
     _children = [[NSMutableArray alloc] init];
    
    return self;
}

- (NSString*) getType {
    return [NSString stringWithCString:_atomWrapper.atom->getType().c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSString*) getName {
    return [NSString stringWithCString:_atomWrapper.atom->getName().c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSString*) getDescription {
    return [NSString stringWithCString:_atomWrapper.atom->description(1).c_str()
                       encoding:[NSString defaultCStringEncoding]];
}

- (NSString*) getHexString {
    return @"";
}

- (int) getDepth {
    return _depth;
}


@end