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
        
        tableView.reloadData()
    }
    
    func displayAtom( atom: Atom, depth: Int ) {
        if ( depth > 0 ) {
            let indent = String( count: depth, repeatedValue: Character( " " ) )
            print( indent + atom.getType() + " - " + atom.getName())
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
        let cell = tableView.dequeueReusableCellWithIdentifier(atomCellIdentifier) ?? UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: atomCellIdentifier)
        cell.accessoryType = .DetailButton
        cell.textLabel?.text = atoms[indexPath.item].getType()
        cell.detailTextLabel?.text = atoms[indexPath.item].getName()
        
        return cell;

    }
    
    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
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