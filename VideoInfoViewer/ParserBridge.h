//
//  ObjC.h
//  VideoInfoViewer
//
//  Created by Hool, Rory on 7/22/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Atom;
struct AtomWrapper;
struct ParserWrapper;

@interface ParserBridge : NSObject

@property (nonatomic) struct ParserWrapper parserWrapper;

- (Atom*) parseFile: (NSString*) filePath;
- (Atom*) transformAtom: (struct AtomWrapper) atomWrapper : (NSInteger) depth;
- (NSString*) getAtomBytes: (Atom*) atom;
@end
