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
import MobileCoreServices
import CoreData
import AVFoundation
import Photos
import GoogleMobileAds

class MainViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var videos = [Video]()
    
    @IBOutlet
    var tableView: UITableView!
    
    var activityView: UIActivityIndicatorView?
    
    var selectedAsset: PHAsset?
    
    var bannerView: GADBannerView?
    
    let videoManager = VideoManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Video Info Viewer"
        
        let openButton = UIBarButtonItem()
        openButton.title = "Open"
        openButton.action = #selector(MainViewController.clickOpen(_:))
        openButton.target = self
        
        self.navigationItem.rightBarButtonItem = openButton
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.loadVideos()
        
        setupAd()
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "MainViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [NSObject : AnyObject])
        }
    }
    
    func loadVideos() {
        videos = videoManager.getVideos()
        self.tableView.reloadData()
    }
    
    func setupAd() {
        if let admobFile = NSBundle.mainBundle().URLForResource("admob", withExtension: "txt") {
            do {
                let adUnitId = try NSString(contentsOfURL: admobFile, encoding: NSUTF8StringEncoding)
                
                if adUnitId.length > 0 {
                    self.navigationController!.setToolbarHidden(false, animated: false)
                    bannerView = GADBannerView(adSize: kGADAdSizeBanner)
                    bannerView?.adUnitID = adUnitId as String
                    bannerView?.rootViewController = self
                    self.navigationController?.toolbar.addSubview(bannerView!)
                    let request = GADRequest()
                    request.testDevices = [kGADSimulatorID, "23797593a5ec6ac21a727ffb8abfd51c"]
                    bannerView?.loadRequest(request)
                }
            } catch _ {
                print("Failed to load ad")
            }
        }
    }
    
    func handleURL(url: NSURL) {
        showActivityIndicator()
        videoManager.addVideoFromURL(url, completionHandler: { video in
            dispatch_async(dispatch_get_main_queue()) {
                self.removeActivityIndicator()
                if let video = video {
                    self.loadVideos()
                    self.viewVideo(video)
                }
            }
        
        })
    }
    
    @IBAction func clickOpen(sender: UIBarButtonItem) {
        
        if checkPhotoAccess(sender) {
            let selectAlbumController = self.storyboard!.instantiateViewControllerWithIdentifier("selectAlbum") as!     SelectAlbumController
        
            selectAlbumController.didSelectAsset = didSelectAsset
        
            if let navController = parentViewController as? UINavigationController {
                navController.pushViewController(selectAlbumController, animated: true)
            }
        }
    }
    
    func checkPhotoAccess(sender: UIBarButtonItem) -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .Authorized:
            return true
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization() { status in
                switch status {
                case .Authorized:
                    self.clickOpen(sender)
                    break
                default:
                    break
                }
            }
            return false
        case .Restricted:
            return false
        case .Denied:
            let alert = UIAlertController(
                title: "Need Authorization",
                message: "Authorize this app " +
                "to access your Photo library?",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(
                title: "No", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(
                title: "OK", style: .Default, handler: {
                    _ in
                    let url = NSURL(string:UIApplicationOpenSettingsURLString)!
                    UIApplication.sharedApplication().openURL(url)
            }))
            self.presentViewController(alert, animated:true, completion:nil)
            return false
        }
    }
    
    func didSelectAsset(asset: PHAsset!) {
        
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.version = .Original
        videoRequestOptions.networkAccessAllowed = true
        
        selectedAsset = asset
        
        if let assetId = selectedAsset?.localIdentifier {
            
            if let video = videoManager.getVideoByAssetId(assetId) {
                videoManager.updateOpenDate(video)
                self.loadVideos()
                self.viewVideo(video)
                return
            }

        }
        
        PHImageManager().requestAVAssetForVideo(
            asset, options:
            videoRequestOptions,
            resultHandler: handleAVAssetRequestResult )
    }
    
    func handleAVAssetRequestResult(avAsset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject: AnyObject]?) {
        guard let avUrlAsset = avAsset as? AVURLAsset else { return }
        
        if let phAsset = selectedAsset {
            showActivityIndicator()
            videoManager.addVideoFromAVURLAsset(avUrlAsset, phAsset:phAsset, completionHandler: { video in
                dispatch_async(dispatch_get_main_queue()) {
                    self.removeActivityIndicator()
                    if let video = video {
                        self.loadVideos()
                        self.viewVideo(video)
                    }
                }
                
            })
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        
        let video = self.videos[indexPath.row]
        
        if let videoURL = video.videoURL {
            cell.textLabel?.text = videoURL.lastPathComponent
        }
        
        if let thumbURL = video.thumbURL {
            let imageSize = Double(cell.contentView.frame.height)
            cell.imageView?.image = cropToBounds(UIImage(named: thumbURL.path!)!, width:imageSize, height:imageSize )
        }
        
        return cell
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage: UIImage = UIImage(CGImage: image.CGImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let video = self.videos[indexPath.row]
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "assetId == %@", video.assetId)
        
        do {
            let result = try managedContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
            if (result.count == 1) {
                let object = result[0]
                object.setValue(NSDate(), forKey: "openDate")
                try managedContext.save()
            }
        } catch {
            fatalError("Failed to fetch video: \(error)")
        }
        
        self.loadVideos()
        viewVideo(video)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func viewVideo(video:Video) {
        let nc = parentViewController as? UINavigationController
        if let navController = nc {
            let videoDetailsController = self.storyboard!.instantiateViewControllerWithIdentifier("videoDetails") as! VideoDetailsViewController
            videoDetailsController.video = video
            navController.pushViewController(videoDetailsController, animated: true)
        }
    }
    
    func showActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            self.activityView!.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
            self.activityView!.center = self.view.center
            self.activityView!.frame = self.view.frame
            
            self.view.addSubview(self.activityView!)
            self.activityView!.startAnimating()
        }
    }
    
    func removeActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) {
            if let activityView = self.activityView {
                activityView.stopAnimating()
                activityView.removeFromSuperview()
            }
        }
    }
}

