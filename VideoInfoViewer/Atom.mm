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
    _hidden = false;
    _collapsed = false;
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
    return [NSString stringWithCString:_atomWrapper.atom->getContent().c_str()
                       encoding:[NSString defaultCStringEncoding]];
}

- (NSString*) getHexString {
    return @"";
}

- (int) getDepth {
    return _depth;
}

- (void) setIsHidden:(bool)hidden {
    _hidden = hidden;
    
    
    if ( _hidden || !_collapsed ) {
        for( Atom* atom in _children ) {
            [atom setIsHidden:_hidden];
        }
    }
}

- (void) setIsCollapsed:(bool)collapsed {
    _collapsed = collapsed;
    for( Atom* atom in _children ) {
        [atom setIsHidden:_collapsed];
    }
}


@end