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

internal class AtomViewController: UIViewController {
    
    var atom: Atom?

    @IBOutlet weak var atomDescription: UILabel!
    @IBOutlet weak var atomName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.title = atom?.getType()
        atomName.text = atom?.getName()
        atomDescription.text = atom?.getDescription()
    }
    
}