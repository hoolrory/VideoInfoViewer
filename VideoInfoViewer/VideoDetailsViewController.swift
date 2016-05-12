//
//  VideoDetailsViewController.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 5/9/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import UIKit

class VideoDetailsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Video Info"
        
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        backButton.action = #selector(VideoDetailsViewController.clickBack(_:))
        backButton.target = self
        
        self.navigationItem.leftBarButtonItem = backButton
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
