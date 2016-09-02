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

#import "ParserBridge.h"

#import "Atom.h"
#include "MP4.Parser.h"
#import "AtomWrapper.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAITracker.h"

struct ParserWrapper {
    MP4::Parser* parser;
};

@implementation ParserBridge

- (void)dealloc {
    delete _parserWrapper.parser;
}

- (Atom*) parseFile: (NSString*) filePath
{
    const char *cFilePath=[filePath UTF8String];
    
    _parserWrapper = ParserWrapper();
    _parserWrapper.parser = new MP4::Parser((char*)cFilePath);
    
    MP4::Atom *rootAtom = _parserWrapper.parser->getRootAtom();
    
    AtomWrapper w;
    w.atom = rootAtom;
    return [self transformAtom:w:0];
}

- (Atom*) transformAtom: (AtomWrapper) atomWrapper : (NSInteger) depth
{
    Atom* atom = [[Atom alloc] init];
    atom.atomWrapper = atomWrapper;
    atom.depth = depth;
    MP4::ContainerAtom *containerAtom = dynamic_cast<MP4::ContainerAtom*>( atomWrapper.atom );
    if( containerAtom ) {
        std::vector<MP4::Atom*> children = containerAtom->getChildren();
        for(std::vector<MP4::Atom*>::iterator it = children.begin(); it != children.end(); ++it) {
            AtomWrapper childWrapper;
            childWrapper.atom = ( * it );
            Atom* child = [self transformAtom:childWrapper:depth+1];
            [atom.children addObject:child];
            
            
            MP4::UnknownAtom *unknownAtom = dynamic_cast<MP4::UnknownAtom*>( childWrapper.atom );
            if( unknownAtom ) {
                id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                
                NSString *type = [NSString stringWithCString:unknownAtom->getType().c_str()
                                   encoding:[NSString defaultCStringEncoding]];
                
                [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Video Info"
                                                                      action:@"Found UnknownBox"
                                                                       label:type
                                                                       value:nil] build]];
            }
        }
    }
    
    return atom;
}


- (NSString*) getAtomBytes: (Atom*) atom;
{
    std::string bytes = _parserWrapper.parser->getBytes(atom.getAtomWrapper.atom);
    return [NSString stringWithFormat:@"%s",bytes.c_str()];
}
@end


