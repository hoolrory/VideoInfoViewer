//
//  VideoDetailsViewController.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 5/9/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import UIKit

class VideoDetailsViewController: UIViewController {

    var videoURL: NSURL?
    var thumbnailURL: NSURL?
    
    @IBOutlet weak var thumbnailView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Video Info"
        
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        backButton.action = #selector(VideoDetailsViewController.clickBack(_:))
        backButton.target = self
        
        self.navigationItem.leftBarButtonItem = backButton
        
        thumbnailView?.image = UIImage(named: thumbnailURL!.path! )
    }
    
    @IBAction func clickBack(sender: UIBarButtonItem) {
        let nc = parentViewController as? UINavigationController
        if let navController = nc {
            navController.popViewControllerAnimated(true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
