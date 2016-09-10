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

import UIKit
import AVFoundation
import AVKit

class VideoDetailsViewController: UIViewController {

    var video: Video?
    
    @IBOutlet weak var thumbnailView: UIImageView!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var atomStructureButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Video Info"
        
        thumbnailView?.image = UIImage(named: video!.thumbURL!.path!)
        
        updateProperties()
        
        let image = UIImage(named: "ic_play_circle_filled_white_48pt.png")?.imageWithRenderingMode(.AlwaysTemplate)
        playButton.setImage(image, forState: .Normal)
        playButton.tintColor = UIColor.whiteColor()
        playButton.alpha = 0.8
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
    
    @IBAction func onClickAtomStructureButton(sender: UIButton) {
        let nc = parentViewController as? UINavigationController
        if let navController = nc {
            let atomStructureController = self.storyboard!.instantiateViewControllerWithIdentifier("atomStructure") as! AtomStructureViewController
            atomStructureController.video = video
            navController.pushViewController(atomStructureController, animated: true)
        }
    }
    
    @IBAction func onClickPlayButton(sender: UIButton) {
        if let videoURL = video?.videoURL {
            let player = AVPlayer(URL: videoURL)
            let playerController = AVPlayerViewController()
            playerController.player = player
            self.presentViewController(playerController, animated: true) {
                player.play()
            }
        }
    }
}
