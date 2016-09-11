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
    @IBOutlet weak var rawDataLabel: UILabel!
    @IBOutlet weak var rawData: UITextView!
    @IBOutlet weak var loadRawDataButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = atom?.getType()
        atomName.text = atom?.getName()
        atomContent.text = atom?.getDescription()
        
        atomContent.textContainerInset = UIEdgeInsetsMake(0, 10, 0, 10)
        rawData.textContainerInset = UIEdgeInsetsMake(0, 10, 0, 10)
        loadRawDataButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20)
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "AtomViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [NSObject : AnyObject])
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
    }
    
    @IBAction func onClickLoadRawData(sender: AnyObject) {
        loadRawDataButton.removeFromSuperview()
        
        if let parserBridge = parserBridge {
            
            rawDataLabel.text = "Raw Data"
            let atomBytes = parserBridge.getAtomBytes(atom!)
            if atomBytes != nil {
                rawData.text = atomBytes
            }
        }
        
        stackView.setNeedsUpdateConstraints()
        stackView.updateConstraintsIfNeeded()
        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()
        delay(0.1) {
            self.view.setNeedsUpdateConstraints()
            self.view.updateConstraintsIfNeeded()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}