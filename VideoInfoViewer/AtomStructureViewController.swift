//
//  AtomStructureViewController.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 7/26/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import Foundation

import UIKit

class AtomStructureViewController: UITableViewController {
    
    var videoURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ObjC.test(videoURL?.path)
    }
}