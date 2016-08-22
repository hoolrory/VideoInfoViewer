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
@property (nonatomic) bool hidden;
@property (nonatomic) bool collapsed;

- (NSString*) getType;
- (NSString*) getName;
- (NSString*) getDescription;
- (NSString*) getHexString;
- (int) getDepth;
- (void) setIsHidden: (bool) hidden;
- (void) setIsCollapsed: (bool) collapsed;

@end

#endif /* Atom_h */
