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
    
    let atomCellIdentifier = "atomCell"
    
    var activityView: UIActivityIndicatorView?
    
    var video: Video?
    
    var rootAtom: Atom?
    var atoms = [Atom]()
    var parserBridge: ParserBridge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Atoms"
        
        showActivityIndicator()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.parserBridge = ParserBridge()
            if let videoURL = self.video?.videoURL {
                self.rootAtom = self.parserBridge!.parseFile(videoURL.path)
                self.displayAtom(self.rootAtom!, depth: 0)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.removeActivityIndicator()
                self.tableView.reloadData()
            }
        }
        
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        
        let footerView = UIView()
        footerView.frame = CGRectMake(0, 0, tableView.frame.width, 0)
        tableView.tableFooterView = footerView
        
        self.view.backgroundColor = UIColor(hex: 0xC8C7CC)
        self.navigationController?.navigationBar.translucent = false
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "AtomStructureViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [NSObject : AnyObject])
        }
    }
    
    func displayAtom(atom: Atom, depth: Int) {
        if depth > 0 {
            atoms.append(atom)
        }
        for child in atom.children {
            if let child = child as? Atom {
                displayAtom(child, depth: depth + 1)
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return atoms.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(atomCellIdentifier) as? AtomStructureViewCell ?? AtomStructureViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: atomCellIdentifier)
        cell.accessoryType = .DetailButton
        
        let atom = atoms[indexPath.item]
        
        cell.typeLabel?.text = atom.getType()
        cell.nameLabel?.text = atom.getName()
        
        let image = createImage(atom.getDepth(), totalHeight: 70)
        if let image = image {
            cell.paddingView?.image = image
            cell.paddingView?.frame = CGRectMake(0, 0, image.size.width, image.size.height)
            
        } else {
            cell.paddingView?.image = nil
        }
        
        if atom.children.count > 0 {
            cell.collapseImageView?.image = UIImage(named:"ic_keyboard_arrow_down.png")
        } else {
            cell.collapseImageView?.image = UIImage(named:"empty_space.png")
        }
        
        if atom.collapsed {
            cell.collapseImageView?.transform = CGAffineTransformMakeRotation(-90*CGFloat(M_PI/180))
        } else {
            cell.collapseImageView?.transform = CGAffineTransformMakeRotation(0)
        }
        
        let offset = CGFloat((atom.getDepth()-1) * 10)
        if let oldConstraint = cell.leftConstraint {
            oldConstraint.active = false
        }
        cell.leftConstraint = cell.collapseImageView?.leadingAnchor.constraintEqualToAnchor(cell.collapseImageView?.superview?.leadingAnchor, constant: offset)
        cell.leftConstraint?.active = true
        
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.contentView.layoutMargins = UIEdgeInsetsZero
        cell.tintColor = UIColor.blackColor()
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(hex: 0x41A3E1)
        cell.selectedBackgroundView = bgColorView

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let atom = atoms[indexPath.item]
        if atom.hidden {
            return 0
        } else {
            return tableView.rowHeight
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let atom = atoms[indexPath.item]
        return atom.children.count > 0
    }
    
    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let atom = atoms[indexPath.item]
        atom.setIsCollapsed(!atom.collapsed)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? AtomStructureViewCell {
                
                let degrees = atom.collapsed ? CGFloat(-90) : CGFloat(0)
                
                UIView.animateWithDuration(0.5) { () -> Void in
                    cell.collapseImageView?.transform = CGAffineTransformMakeRotation(degrees * CGFloat(M_PI/180))
                }
            }
    
        tableView.beginUpdates()
        tableView.endUpdates()
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func createImage(depth: Int32, totalHeight: CGFloat?) -> UIImage? {
        if depth == 1 {
            return nil
        }
        
        let offset = CGFloat((depth-1) * 10)
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(offset, totalHeight!), false, 0.0)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        UIGraphicsPushContext(context)
        CGContextSetFillColorWithColor(context, UIColor(hex: 0xC8C7CC).CGColor)
        CGContextFillRect(context, CGRectMake(0, 0, offset, totalHeight!))
        UIGraphicsPopContext()
        
        let outputImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return outputImage
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let nc = parentViewController as? UINavigationController
        if let navController = nc {
            let atomController = self.storyboard!.instantiateViewControllerWithIdentifier("atom") as! AtomViewController
            atomController.atom = atoms[indexPath.item]
            atomController.parserBridge = parserBridge
            navController.pushViewController(atomController, animated: true)
        }
    }
    
    func showActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            self.activityView!.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
            self.activityView!.center = self.view.center
            self.activityView!.frame = self.view.frame
            
            self.view.addSubview(self.activityView!)
            self.activityView!.startAnimating()
        }
    }
    
    func removeActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) {
            if let activityView = self.activityView {
                activityView.stopAnimating()
                activityView.removeFromSuperview()
            }
        }
    }
}