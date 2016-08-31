//
//  VideoDetailsViewController.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 5/9/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import UIKit

class VideoDetailsViewController: UIViewController {

    var video: Video?
    
    @IBOutlet weak var thumbnailView: UIImageView!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var atomStructureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Video Info"
        
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        backButton.action = #selector(VideoDetailsViewController.clickBack(_:))
        backButton.target = self
        
        self.navigationItem.leftBarButtonItem = backButton
        
        thumbnailView?.image = UIImage(named: video!.thumbURL!.path! )
        
        updateProperties()
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "VideoDetailsViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [NSObject : AnyObject])
        }
    }
    
    func updateProperties() {
        if let tv = textView {
            if let videoURL = video?.videoURL {
                let size = MediaUtils.getVideoResolution(videoURL)
                var text = ""
                if let name = videoURL.lastPathComponent {
                    text += "Name:       \(name)\n"
                }
                text += "Resolution: \(Int(size.width))x\(Int(size.height))\n"
                text += "MimeType:   \(MediaUtils.getVideoMimeType(videoURL))\n"
                text += "Frame Rate: \(MediaUtils.getVideoFrameRate(videoURL)) fps\n"
                text += "File Size:  \(MediaUtils.getVideoFileSize(videoURL))\n"
                text += "Duration:   \(MediaUtils.getVideoDurationFormatted(videoURL))\n"
                text += "Bitrate:    \(MediaUtils.getVideoBitrate(videoURL))\n"
                text += "Date:       \(formatDate(video?.creationDate))\n"
                tv.text = text
            }
        }
    }
    
    func formatDate(date: NSDate?) -> String {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = .ShortStyle
        if let date = date {
            return formatter.stringFromDate(date)
        }
        
        return ""
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
    
    @IBAction func onClickAtomStructureButton(sender: UIButton) {
        let nc = parentViewController as? UINavigationController
        if let navController = nc {
            let atomStructureController = self.storyboard!.instantiateViewControllerWithIdentifier("atomStructure") as! AtomStructureViewController
            atomStructureController.video = video
            navController.pushViewController(atomStructureController, animated: true)
        }
    }
}
