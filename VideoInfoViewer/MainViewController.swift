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
    
    var selectedAsset: PHAsset?
    
    var bannerView: GADBannerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Video Info Viewer"
        
        let openButton = UIBarButtonItem()
        openButton.title = "Open"
        openButton.action = #selector(MainViewController.clickOpen(_:))
        openButton.target = self
        
        self.navigationItem.rightBarButtonItem = openButton
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "openDate", ascending: false)]
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            let objects = results as! [NSManagedObject]
            for object in objects {
                videos.append(Video(fromObject: object))
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        setupAd()
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
                    request.testDevices = [kGADSimulatorID]
                    bannerView?.loadRequest(request)
                }
            } catch _ {
                print("Failed to load ad")
            }
        }
    }
    
    @IBAction func clickOpen(sender: UIBarButtonItem) {
        
        let selectAlbumController = self.storyboard!.instantiateViewControllerWithIdentifier("selectAlbum") as! SelectAlbumController
        
        selectAlbumController.didSelectAsset = didSelectAsset
        
        if let navController = parentViewController as? UINavigationController {
            navController.pushViewController(selectAlbumController, animated: true)
        }
    }
    
    func didSelectAsset(asset: PHAsset!) {
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.version = .Original
        videoRequestOptions.networkAccessAllowed = true
        
        selectedAsset = asset
        
        PHImageManager().requestAVAssetForVideo(
            asset, options:
            videoRequestOptions,
            resultHandler: handleAVAssetRequestResult )
    }
   
   func handleAVAssetRequestResult(avAsset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject: AnyObject]?) {
      guard let avUrlAsset = avAsset as? AVURLAsset else { return }
    
      let filemgr = NSFileManager.defaultManager()
      let lastPathComponent = avUrlAsset.URL.lastPathComponent
      let videoName = lastPathComponent != nil ? lastPathComponent! :"video_\(NSDate().timeIntervalSince1970).MOV"
         
      let toURL = getDocumentUrl(videoName)
      let creationDate = selectedAsset?.creationDate
      selectedAsset = nil
      do {
         try filemgr.copyItemAtURL(avUrlAsset.URL, toURL: toURL)
      } catch _ {
         print("Failed to copy")
         return
      }
      
      let thumbnailURL = getDocumentUrl("\(videoName).png")
      let duration = MediaUtils.getVideoDuration(toURL)
      let thumbTime = CMTime(seconds: duration.seconds / 2.0, preferredTimescale: duration.timescale)
      MediaUtils.renderThumbnailFromVideo(toURL, thumbnailURL: thumbnailURL, time: thumbTime)
         
      saveVideo(toURL, thumbnailURL: thumbnailURL, creationDate: creationDate)
   }

    func saveVideo(videoURL: NSURL, thumbnailURL: NSURL, creationDate: NSDate?) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let entity =  NSEntityDescription.entityForName("Video", inManagedObjectContext:managedContext)
        
        let object = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        object.setValue(videoURL.lastPathComponent, forKey: "videoFile")
        object.setValue(thumbnailURL.lastPathComponent, forKey: "thumbFile")
        object.setValue(NSDate(), forKey: "openDate")
        object.setValue(creationDate, forKey: "creationDate")
        
        do {
            try managedContext.save()
            let video = Video(fromObject: object)
            videos.insert(video, atIndex: 0)
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
                self.viewVideo(video)
            }
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func getDocumentUrl(pathComponent : String) -> NSURL {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        guard let documentDirectory: NSURL = urls.first else {
            fatalError("documentDir Error")
        }
        
        return documentDirectory.URLByAppendingPathComponent(pathComponent)
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
        viewVideo(self.videos[indexPath.row])
        
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
}

