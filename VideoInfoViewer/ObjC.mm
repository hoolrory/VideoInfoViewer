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

@implementation ObjC

+ (Atom*) parseFile: (NSString*) filePath
{
    const char *cFilePath=[filePath UTF8String];
    MP4::Parser * parser;
    
    parser = new MP4::Parser((char*)cFilePath);
    
    MP4::Atom *rootAtom = parser->getRootAtom();
    
    AtomWrapper w;
    w.atom = rootAtom;
    return [self transformAtom:w];
}

+ (Atom*) transformAtom: (AtomWrapper) atomWrapper
{
    Atom* atom = [[Atom alloc] init];
    atom.type = [NSString stringWithCString:atomWrapper.atom->getType().c_str()
                                   encoding:[NSString defaultCStringEncoding]];
    atom.name = [NSString stringWithCString:atomWrapper.atom->subtitle().c_str()
                                   encoding:[NSString defaultCStringEncoding]];
    
    MP4::ContainerAtom *containerAtom = dynamic_cast<MP4::ContainerAtom*>( atomWrapper.atom );
    if( containerAtom ) {
        std::vector<MP4::Atom*> children = containerAtom->getChildren();
        for(std::vector<MP4::Atom*>::iterator it = children.begin(); it != children.end(); ++it) {
            AtomWrapper w;
            w.atom = ( * it );
            Atom* child = [self transformAtom:w];
            [atom.children addObject:child];
            // std::cout << "Adding Child " << ( * it )->subtitle() << " to container " << containerAtom->getType() << " with " << [atom.children count] << "\n";
        }
    }
    
    return atom;
}
@end


