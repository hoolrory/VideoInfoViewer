/**
 Copyright (c) 2016 Rory Hool
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 **/

#import <Foundation/Foundation.h>
#import "Atom.h"
#import "AtomWrapper.h"

@implementation Atom

- init {
    self = [super init];
    
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

- (struct AtomWrapper) getAtomWrapper {
    return _atomWrapper;
}


@end