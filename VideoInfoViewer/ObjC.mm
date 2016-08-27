//
//  ObjC.m
//  VideoInfoViewer
//
//  Created by Hool, Rory on 7/22/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

#import "ObjC.h"

#import "Atom.h"
#include "MP4.Parser.h"
#import "AtomWrapper.h"

struct ParserWrapper {
    MP4::Parser* parser;
};

@implementation ObjC

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


