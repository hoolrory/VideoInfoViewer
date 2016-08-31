//
//  SelectAlbumController.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 8/23/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import Foundation

import UIKit
import Photos

public class SelectAlbumController: UITableViewController, PHPhotoLibraryChangeObserver {
    
    struct AlbumItem {
        var title: String!
        var image: UIImage!
        var collection: PHAssetCollection?
    }
    
    public var didSelectAsset: ((PHAsset!) -> ())?
    
    var albums = Array<AlbumItem>()
    
    let activityIndicatorTag = 100
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Albums", comment: "")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(SelectAlbumController.cancelAction))
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = self.view.center
        view.addSubview(activityIndicator)
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        loadData()
    }
    
    override public func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "SelectAlbumController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [NSObject : AnyObject])
        }
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    func loadData() {
        tableView.userInteractionEnabled = false
        
        if let activityIndicator = self.view.viewWithTag(self.activityIndicatorTag) as? UIActivityIndicatorView {
            activityIndicator.startAnimating()
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            self.albums.removeAll(keepCapacity: false)
            
            let smartAlbums = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.AlbumRegular, options: nil)
            self.processCollectionList(smartAlbums)
            
            let userCollections = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
            self.processCollectionList(userCollections)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
                self.tableView.userInteractionEnabled = true
                
                if let activityIndicator = self.view.viewWithTag(self.activityIndicatorTag) as? UIActivityIndicatorView {
                    activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("albumCell", forIndexPath: indexPath)
        cell.imageView?.image = albums[indexPath.row].image
        cell.textLabel?.text = NSLocalizedString(albums[indexPath.row].title, comment: "")
        
        return cell
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectVideoController = self.storyboard!.instantiateViewControllerWithIdentifier("selectVideo") as! SelectVideoController
        selectVideoController.collection = albums[indexPath.row].collection
        selectVideoController.didSelectAsset = didSelectAsset
        selectVideoController.title = albums[indexPath.row].title
        navigationController?.pushViewController(selectVideoController, animated: true)
    }
    
    public func photoLibraryDidChange(changeInstance: PHChange) {
        loadData()
    }
    
    func processCollectionList(collections:PHFetchResult) {
        for i: Int in 0 ..< collections.count {
            if let collection = collections[i] as? PHAssetCollection {
                
                if fetchVideos(collection).count == 0 {
                    continue
                }
                
                var title: String?
                
                switch collection.assetCollectionSubtype {
                case .SmartAlbumFavorites:
                    title = "Favorites"
                    break
                case .SmartAlbumPanoramas:
                    title = "Panoramas"
                    break
                case .SmartAlbumVideos:
                    title = "Videos"
                    break
                case .SmartAlbumTimelapses:
                    title = "Time Lapses"
                    break
                case .SmartAlbumUserLibrary:
                    continue
                default:
                    title = collection.localizedTitle
                    break
                }
                
                self.albums.append(AlbumItem(title: title, image: self.getLastThumbnail(collection), collection: collection))
            }
        }
    }
    
    func cancelAction() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func getLastThumbnail(collection: PHAssetCollection?) -> UIImage? {
        var thumbnail: UIImage? = nil
        
        if let lastAsset = fetchVideos(collection!).lastObject as? PHAsset {
            
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.FastFormat
            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.Exact
            imageRequestOptions.synchronous = true
            
            let targetWidthHeight = 64 * UIScreen.mainScreen().scale
            
            PHImageManager.defaultManager().requestImageForAsset(lastAsset, targetSize: CGSizeMake(targetWidthHeight, targetWidthHeight), contentMode: PHImageContentMode.AspectFill, options: imageRequestOptions, resultHandler: { (image: UIImage?, info :[NSObject : AnyObject]?) -> Void in
                thumbnail = image
            })
        }
        
        return thumbnail
    }
    
    func fetchVideos(collection: PHAssetCollection) -> PHFetchResult {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Video.rawValue)
        
        return PHAsset.fetchAssetsInAssetCollection(collection, options: fetchOptions)
    }
}