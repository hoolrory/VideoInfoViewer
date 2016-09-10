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
    var parserBridge: ParserBridge?

    @IBOutlet weak var atomName: UILabel!
    @IBOutlet weak var atomContent: UITextView!
    @IBOutlet weak var loadRawDataButton: UIButton!
    
    var originalConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.title = atom?.getType()
        atomName.text = atom?.getName()
        atomContent.text = atom?.getDescription()
        
        let offset = CGFloat(-20)
        
        originalConstraint = atomContent?.bottomAnchor.constraintEqualToAnchor(loadRawDataButton?.topAnchor, constant: offset)
        originalConstraint?.active = true
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "AtomViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [NSObject : AnyObject])
        }
    }
    
    @IBAction func onClickLoadRawData(sender: AnyObject) {
        
        originalConstraint?.active = false
        
        let offset = CGFloat(-20)
        
        let newConstraint = atomContent?.bottomAnchor.constraintEqualToAnchor(atomContent.superview?.bottomAnchor, constant: offset)
        newConstraint?.active = true
        
        loadRawDataButton.removeFromSuperview()
        
        if let parserBridge = parserBridge {
            
            atomContent.text.appendContentsOf("\n")
            let atomBytes = parserBridge.getAtomBytes(atom!)
            if atomBytes != nil {
                atomContent.text.appendContentsOf(atomBytes)
            }
        }
        
    }
}