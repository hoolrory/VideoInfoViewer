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
- (struct AtomWrapper) getAtomWrapper;

@end

#endif /* Atom_h */
