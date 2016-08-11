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

@property NSString *type;
@property NSString *name;
@property (nonatomic, retain) NSMutableArray<Atom*>* children;

+ (NSString*) getDescription;
+ (NSString*) getHexString;

@end

#endif /* Atom_h */
