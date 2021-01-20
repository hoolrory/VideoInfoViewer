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
    
    var videoManager: VideoManager?
    
    @IBOutlet weak var thumbnailView: UIImageView!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var atomStructureButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thumbnailView?.image = UIImage(named: video!.thumbURL!.path)
        
        updateProperties()
        
        let image = UIImage(named: "ic_play_circle_filled_white_48pt.png")?.withRenderingMode(.alwaysTemplate)
        playButton.setImage(image, for: UIControl.State())
        playButton.tintColor = UIColor.white
        playButton.alpha = 0.8
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "VideoDetailsViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [AnyHashable: Any])
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    func updateProperties() {
        if let tv = textView {
            if let videoURL = video?.videoURL {
                let size = MediaUtils.getVideoResolution(videoURL)
                var text = ""
                text += "Name:       \(videoURL.lastPathComponent)\n"
                text += "Resolution: \(Int(size.width))x\(Int(size.height))\n"
                text += "MimeType:   \(MediaUtils.getVideoMimeType(videoURL))\n"
                text += "Frame Rate: \(MediaUtils.getVideoFrameRate(videoURL)) fps\n"
                text += "File Size:  \(MediaUtils.getVideoFileSize(videoURL))\n"
                text += "Duration:   \(MediaUtils.getVideoDurationFormatted(videoURL))\n"
                text += "Bitrate:    \(MediaUtils.getVideoBitrate(videoURL))\n"
                text += "Date:       \(formatDate(video?.creationDate as Date?))\n"
                tv.text = text
            }
        }
    }
    
    func formatDate(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = .short
        if let date = date {
            return formatter.string(from: date)
        }
        
        return ""
    }
    
    @IBAction func onClickRemoveButton(_ sender: Any) {
        if let video = video {
            videoManager?.removeVideo(video: video)
        }
        if let navController = parent as? UINavigationController {
            navController.popViewController(animated: true)
        }
    }
    
    @IBAction func onClickAtomStructureButton(_ sender: UIButton) {
        let nc = parent as? UINavigationController
        if let navController = nc {
            let atomStructureController = self.storyboard!.instantiateViewController(withIdentifier: "atomStructure") as! AtomStructureViewController
            atomStructureController.video = video
            navController.pushViewController(atomStructureController, animated: true)
        }
    }
    
    @IBAction func onClickPlayButton(_ sender: UIButton) {
        if let tracker = GAI.sharedInstance().defaultTracker {
            let dictionary = GAIDictionaryBuilder.createEvent(withCategory: "Video Info", action: "Clicked play button", label: "", value: 0).build() as NSDictionary
            let event = dictionary as? [AnyHashable: Any] ?? [:]
            tracker.send(event)
        }
        if let videoURL = video?.videoURL {
            let player = AVPlayer(url: videoURL as URL)
            let playerController = AVPlayerViewController()
            playerController.player = player
            self.present(playerController, animated: true) {
                player.play()
            }
        }
    }
}
