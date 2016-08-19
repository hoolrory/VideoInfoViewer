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
    
    let atomCellIdentifier = "atomCell";
    
    var videoURL: NSURL?
    
    var rootAtom: Atom?
    var count: Int = 0
    var atoms = [Atom]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Atoms"
        
        rootAtom = ObjC.parseFile(videoURL?.path)
        displayAtom( rootAtom!, depth: 0 );
        
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        
        tableView.reloadData()
    }
    
    func displayAtom( atom: Atom, depth: Int ) {
        if ( depth > 0 ) {
            let indent = String( count: depth, repeatedValue: Character( " " ) )
            print( indent + atom.getType() + " - " + atom.getName() )
            atoms.append( atom )
            count += 1
        }
        for child in atom.children {
            if let child = child as? Atom {
                displayAtom( child, depth: depth + 1 )
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(atomCellIdentifier) as? AtomStructureViewCell ?? AtomStructureViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: atomCellIdentifier)
        cell.accessoryType = .DetailButton
        
        let atom = atoms[indexPath.item]
        
        cell.typeLabel?.text = atom.getType()
        cell.nameLabel?.text = atom.getName()
        
        let height = cell.contentView.frame.height + CGFloat(10)
        let image = createImage(atom.getDepth(), totalHeight: height)
        if let image = image {
            cell.paddingView?.image = image
            cell.paddingView?.frame = CGRectMake(0, 0, image.size.width, image.size.height)
            
            //cell.collapseImageView?.leadingAnchor.constraintEqualToAnchor(cell.collapseImageView?.superview!.trailingAnchor).active = false
            //cell.collapseImageView?.leadingAnchor.constraintEqualToAnchor(cell.paddingView?.trailingAnchor).active = true
            
            print("atom \(atom.getType()) - image size = \(image.size.width)")
        } else {
            cell.paddingView?.image = nil
            
        }
        
        if atom.children.count > 0 {
            cell.collapseImageView?.image = UIImage(named:"ic_keyboard_arrow_down.png")
        } else {
            cell.collapseImageView?.image = UIImage(named:"empty_space.png")
        }
        
        // let margins = cell.contentView
        let offset = CGFloat((atom.getDepth()-1) * 10)
        print("atom \(atom.getType()) - Setting collapseImageView anchor to constant \(offset)")
        if let oldConstraint = cell.leftConstraint {
            oldConstraint.active = false
        }
        cell.leftConstraint = cell.collapseImageView?.leadingAnchor.constraintEqualToAnchor(cell.collapseImageView?.superview?.leadingAnchor, constant: offset )
        cell.leftConstraint?.active = true
        
        
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.contentView.layoutMargins = UIEdgeInsetsZero
        cell.tintColor = UIColor.blackColor()
        
        print(cell.contentView.layer.borderWidth);
        let bgColorView = UIView()
        bgColorView.backgroundColor =  UIColor(red: 66/255, green: 163/255, blue: 225/255, alpha: 1)
        cell.selectedBackgroundView = bgColorView

        return cell;
    }
    
    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func createImage(depth: Int32, totalHeight: CGFloat?) -> UIImage? {
        
        if ( depth == 1 ) {
            return nil
        }
        let offset = CGFloat((depth-1) * 10)
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake( offset, totalHeight!), false, 0.0)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        UIGraphicsPushContext(context)
        CGContextSetFillColorWithColor(context, UIColor(red: 200/255, green:199/255, blue:204/255, alpha:1).CGColor)
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
            navController.pushViewController(atomController, animated: true)
        }
    }
}