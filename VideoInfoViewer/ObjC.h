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

@interface ObjC : NSObject
+ (Atom*) parseFile: (NSString*) filePath;
+ (Atom*) transformAtom: (struct AtomWrapper) atomWrapper : (NSInteger) depth;
@end
