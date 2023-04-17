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
    
    let parsingQueue = DispatchQueue(label: "parsingQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Atoms"
        
        showActivityIndicator()
        
        parsingQueue.async {
            self.parserBridge = ParserBridge()
            if let videoURL = self.video?.videoURL {
                self.rootAtom = self.parserBridge!.parseFile(videoURL.path)
                self.displayAtom(self.rootAtom!, depth: 0)
            }
            
            DispatchQueue.main.async {
                self.removeActivityIndicator()
                self.tableView.reloadData()
            }
        }
        
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        
        let footerView = UIView()
        footerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0)
        tableView.tableFooterView = footerView
        
        self.view.backgroundColor = UIColor(hex: 0xC8C7CC)
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "AtomStructureViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [AnyHashable: Any])
        }
    }
    
    func displayAtom(_ atom: Atom, depth: Int) {
        if depth > 0 {
            atoms.append(atom)
        }
        for child in atom.children {
            if let child = child as? Atom {
                displayAtom(child, depth: depth + 1)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return atoms.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: atomCellIdentifier) as? AtomStructureViewCell ?? AtomStructureViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: atomCellIdentifier)
        cell.accessoryType = .detailButton
        
        let atom = atoms[indexPath.item]
        
        cell.typeLabel?.text = atom.getType()
        cell.nameLabel?.text = atom.getName()
        
        let image = createImage(atom.getDepth(), totalHeight: 70)
        if let image = image {
            cell.paddingView?.image = image
            cell.paddingView?.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            
        } else {
            cell.paddingView?.image = nil
        }
        
        if atom.children.count > 0 {
            cell.collapseImageView?.image = UIImage(named:"ic_keyboard_arrow_down.png")
        } else {
            cell.collapseImageView?.image = UIImage(named:"empty_space.png")
        }
        
        if atom.collapsed {
            cell.collapseImageView?.transform = CGAffineTransform(rotationAngle: -90*CGFloat(Double.pi/180))
        } else {
            cell.collapseImageView?.transform = CGAffineTransform(rotationAngle: 0)
        }
        
        let offset = CGFloat((atom.getDepth()-1) * 10)
        if let oldConstraint = cell.leftConstraint {
            oldConstraint.isActive = false
        }
        cell.leftConstraint = cell.collapseImageView?.leadingAnchor.constraint(equalTo: (cell.collapseImageView?.superview?.leadingAnchor)!, constant: offset)
        cell.leftConstraint?.isActive = true
        
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.contentView.layoutMargins = UIEdgeInsets.zero
        cell.tintColor = UIColor.black
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(hex: 0x41A3E1)
        cell.selectedBackgroundView = bgColorView

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let atom = atoms[indexPath.item]
        if atom.hidden {
            return 0
        } else {
            return tableView.rowHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        let atom = atoms[indexPath.item]
        return atom.children.count > 0
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        let atom = atoms[indexPath.item]
        atom.setIsCollapsed(!atom.collapsed)
            if let cell = tableView.cellForRow(at: indexPath) as? AtomStructureViewCell {
                
                let degrees = atom.collapsed ? CGFloat(-90) : CGFloat(0)
                
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    cell.collapseImageView?.transform = CGAffineTransform(rotationAngle: degrees * CGFloat(Double.pi/180))
                }) 
            }
    
        tableView.beginUpdates()
        tableView.endUpdates()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func createImage(_ depth: Int32, totalHeight: CGFloat?) -> UIImage? {
        if depth == 1 {
            return nil
        }
        
        let offset = CGFloat((depth-1) * 10)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: offset, height: totalHeight!), false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        UIGraphicsPushContext(context)
        context.setFillColor(UIColor(hex: 0xC8C7CC).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: offset, height: totalHeight!))
        UIGraphicsPopContext()
        
        let outputImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return outputImage
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let nc = parent as? UINavigationController
        if let navController = nc {
            let atomController = self.storyboard!.instantiateViewController(withIdentifier: "atom") as! AtomViewController
            atomController.atom = atoms[indexPath.item]
            atomController.parserBridge = parserBridge
            navController.pushViewController(atomController, animated: true)
        }
    }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.activityView = UIActivityIndicatorView(style: .gray)
            self.activityView!.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
            self.activityView!.center = self.view.center
            self.activityView!.frame = self.view.frame
            
            self.view.addSubview(self.activityView!)
            self.activityView!.startAnimating()
        }
    }
    
    func removeActivityIndicator() {
        DispatchQueue.main.async {
            if let activityView = self.activityView {
                activityView.stopAnimating()
                activityView.removeFromSuperview()
            }
        }
    }
}
