//
//  Test.h
//  VideoInfoViewer
//
//  Created by Hool, Rory on 8/9/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

#ifndef Atom_h
#define Atom_h

struct AtomWrapper;
@interface Atom : NSObject

@property (nonatomic, retain) NSMutableArray<Atom*>* children;
@property struct AtomWrapper atomWrapper;
@property int depth;

- (NSString*) getType;
- (NSString*) getName;
- (NSString*) getDescription;
- (NSString*) getHexString;
- (int) getDepth;

@end

#endif /* Atom_h */
