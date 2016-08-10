//
//  AtomStructureViewController.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 7/26/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

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