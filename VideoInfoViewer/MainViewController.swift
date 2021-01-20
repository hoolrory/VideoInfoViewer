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

class MainViewController: UIViewController {
    
    var videos = [Video]()
    
    @IBOutlet
    var tableView: UITableView!
    
    var activityView: UIActivityIndicatorView?
    
    var selectedAsset: PHAsset?
    
    let showAds = false
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
        
        let creditsButton = UIBarButtonItem()
        creditsButton.title = "Credits"
        creditsButton.action = #selector(MainViewController.clickCredits(_:))
        creditsButton.target = self
        
        self.navigationItem.leftBarButtonItem = creditsButton
        
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        
        self.navigationItem.backBarButtonItem = backButton
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.delegate = self
        
        if showAds {
            setupAd()
        }
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "MainViewController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [AnyHashable: Any])
        }
        
        self.loadVideos()
    }
    
    func loadVideos() {
        videos = videoManager.getVideos()
        self.tableView.reloadData()
        
        if videos.count == 0 {
            let emptyView = UILabel()
            emptyView.text = "To get started, click \"Open\"\nto select a video."
            emptyView.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.tableView.bounds.height/4)
            emptyView.numberOfLines = 0
            emptyView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            emptyView.backgroundColor = UIColor.white
            emptyView.textAlignment = .center
            self.tableView.tableHeaderView = emptyView
            self.tableView.separatorStyle = .none
        } else {
            self.tableView.tableHeaderView = nil
            self.tableView.separatorStyle = .singleLine
        }
    }
    
    func setupAd() {
        if let admobFile = Bundle.main.url(forResource: "admob", withExtension: "txt") {
            do {
                let adUnitId = try NSString(contentsOf: admobFile, encoding: String.Encoding.utf8.rawValue)
                
                if adUnitId.length > 0 {
                    self.navigationController!.setToolbarHidden(false, animated: false)
                    bannerView = GADBannerView(adSize: kGADAdSizeBanner)
                    bannerView?.adUnitID = adUnitId as String
                    bannerView?.rootViewController = self
                    self.navigationController?.toolbar.addSubview(bannerView!)
                    let request = GADRequest()
                    request.testDevices = [kGADSimulatorID]
                    bannerView?.load(request)
                }
            } catch _ {
                print("Failed to load ad")
            }
        }
    }
    
    func handleURL(_ url: URL) {
        if let tracker = GAI.sharedInstance().defaultTracker {
            let dictionary = GAIDictionaryBuilder.createEvent(withCategory: "Video Info", action: "Video shared to app", label: "", value: 0).build() as NSDictionary
            let event = dictionary as? [AnyHashable: Any] ?? [:]
            tracker.send(event)
        }
        showActivityIndicator()
        videoManager.addVideoFromURL(url, completionHandler: { video in
            DispatchQueue.main.async {
                self.removeActivityIndicator()
                if let video = video {
                    self.loadVideos()
                    self.viewVideo(video)
                }
            }
        
        })
    }
    
    @IBAction func clickOpen(_ sender: UIBarButtonItem) {
        
        if checkPhotoAccess(sender) {
            let selectAlbumController = self.storyboard!.instantiateViewController(withIdentifier: "selectAlbum") as!     SelectAlbumController
        
            selectAlbumController.didSelectAsset = didSelectAsset
        
            if let navController = parent as? UINavigationController {
                navController.pushViewController(selectAlbumController, animated: true)
            }
        }
    }
    
    @IBAction func clickCredits(_ sender: UIBarButtonItem) {
        let creditsController = self.storyboard!.instantiateViewController(withIdentifier: "credits") as!     CreditsViewController
        
        if let navController = parent as? UINavigationController {
            navController.pushViewController(creditsController, animated: true)
        }
    }
    
    func checkPhotoAccess(_ sender: UIBarButtonItem) -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization() { status in
                switch status {
                case .authorized:
                    
                    DispatchQueue.main.async {
                        self.clickOpen(sender)
                    }
                    break
                default:
                    break
                }
            }
            return false
        case .restricted:
            return false
        case .denied:
            let alert = UIAlertController(
                title: "Need Authorization",
                message: "Authorize this app " +
                "to access your Photo library?",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(
                title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(
                title: "OK", style: .default, handler: {
                    _ in
                    let url = URL(string:UIApplication.openSettingsURLString)!
                    UIApplication.shared.openURL(url)
            }))
            self.present(alert, animated:true, completion:nil)
            return false
        }
    }
    
    func didSelectAsset(_ asset: PHAsset?) {
      
        guard let asset = asset else { return }
      
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.version = .original
        videoRequestOptions.isNetworkAccessAllowed = true
        
        selectedAsset = asset
        
        if let assetId = selectedAsset?.localIdentifier {
            
            if let video = videoManager.getVideoByAssetId(assetId) {
                videoManager.updateOpenDate(video)
                self.loadVideos()
                self.viewVideo(video)
                return
            }

        }
        showActivityIndicator()
      
        PHImageManager().requestAVAsset(
            forVideo: asset, options:
            videoRequestOptions,
            resultHandler: handleAVAssetRequestResult)
    }
    
    func handleAVAssetRequestResult(_ avAsset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable: Any]?) {
        guard let avUrlAsset = avAsset as? AVURLAsset else
        {
            removeActivityIndicator()
            return
        }
        
        if let phAsset = selectedAsset {
            videoManager.addVideoFromAVURLAsset(avUrlAsset, phAsset:phAsset, completionHandler: { video in
                DispatchQueue.main.async {
                    self.removeActivityIndicator()
                    if let video = video {
                        self.loadVideos()
                        self.viewVideo(video)
                    }
                }
                
            })
        } else {
            removeActivityIndicator()
        }
    }
    
    func viewVideo(_ video:Video) {
        let nc = parent as? UINavigationController
        if let navController = nc {
            let videoDetailsController = self.storyboard!.instantiateViewController(withIdentifier: "videoDetails") as! VideoDetailsViewController
            videoDetailsController.video = video
            videoDetailsController.videoManager = videoManager
            navController.pushViewController(videoDetailsController, animated: true)
        }
    }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.activityView = UIActivityIndicatorView(style: .gray)
            self.activityView!.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
            self.activityView!.center = self.view.center
            self.activityView!.frame = self.view.frame
            
            self.view.addSubview(self.activityView!)
            self.activityView!.startAnimating()
        }
    }
    
    func removeActivityIndicator() {
        DispatchQueue.main.async {
            if let activityView = self.activityView {
                activityView.stopAnimating()
                activityView.removeFromSuperview()
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = self.videos[indexPath.row]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "assetId == %@", video.assetId)
        
        do {
            let result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            if result.count == 1 {
                let object = result[0]
                object.setValue(Date(), forKey: "openDate")
                try managedContext.save()
            }
        } catch {
            fatalError("Failed to fetch video: \(error)")
        }
        
        self.loadVideos()
        viewVideo(video)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? 50 : 100
    }
}

// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        
        let video = self.videos[indexPath.row]
        
        if let videoURL = video.videoURL {
            cell.textLabel?.text = videoURL.lastPathComponent
        }
        
        cell.imageView?.image = nil
      
      if let image = UIImage(named: video.thumbURL.path ) {
         cell.imageView?.image = image.toSquare()
      }
      
        return cell
    }
}
