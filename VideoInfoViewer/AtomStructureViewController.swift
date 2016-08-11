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

import Foundation

import UIKit

internal class AtomStructureViewController: UITableViewController {
    
    var videoURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let atom = ObjC.parseFile(videoURL?.path)
        print(atom.name);
        if let atom = atom as? Atom {
            if let children = atom.children {
                for child in children {
                    if let child = child as? Atom {
                        print( " - " + child.name );
                    }
                }
            }
        }
    }
}