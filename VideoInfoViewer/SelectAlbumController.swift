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

import Foundation

import UIKit
import Photos

open class SelectAlbumController: UITableViewController {
    
    struct AlbumItem {
        var title: String!
        var image: UIImage!
        var collection: PHAssetCollection?
    }
    
    open var didSelectAsset: ((PHAsset?) -> ())?
    
    var albums = Array<AlbumItem>()
    
    let activityIndicatorTag = 100
    
    let loadDataQueue = DispatchQueue(label: "loadDataQueue")
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Albums", comment: "")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(SelectAlbumController.cancelAction))
        
        let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = self.view.center
        view.addSubview(activityIndicator)
        
        PHPhotoLibrary.shared().register(self)
        
        loadData()
    }
    
    override open func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "SelectAlbumController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [AnyHashable: Any])
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func loadData() {
        tableView.isUserInteractionEnabled = false
        
        if let activityIndicator = self.view.viewWithTag(self.activityIndicatorTag) as? UIActivityIndicatorView {
            activityIndicator.startAnimating()
        }
        
        loadDataQueue.async {
            
            self.albums.removeAll(keepingCapacity: false)
            
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
            self.processCollectionList(smartAlbums as! PHFetchResult<AnyObject>)
            
            let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            self.processCollectionList(userCollections as! PHFetchResult<AnyObject>)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.isUserInteractionEnabled = true
                
                if let activityIndicator = self.view.viewWithTag(self.activityIndicatorTag) as? UIActivityIndicatorView {
                    activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "albumCell", for: indexPath)
        cell.imageView?.image = albums[indexPath.row].image
        cell.textLabel?.text = NSLocalizedString(albums[indexPath.row].title, comment: "")
        
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectVideoController = self.storyboard!.instantiateViewController(withIdentifier: "selectVideo") as! SelectVideoController
        selectVideoController.collection = albums[indexPath.row].collection
        selectVideoController.didSelectAsset = didSelectAsset
        selectVideoController.title = albums[indexPath.row].title
        navigationController?.pushViewController(selectVideoController, animated: true)
    }
    
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? 50 : 100
    }
    
    func processCollectionList(_ collections:PHFetchResult<AnyObject>) {
        for i: Int in 0 ..< collections.count {
            if let collection = collections[i] as? PHAssetCollection {
                
                if fetchVideos(collection).count == 0 {
                    continue
                }
                
                var title: String?
                
                switch collection.assetCollectionSubtype {
                case .smartAlbumFavorites:
                    title = "Favorites"
                    break
                case .smartAlbumPanoramas:
                    title = "Panoramas"
                    break
                case .smartAlbumVideos:
                    title = "Videos"
                    break
                case .smartAlbumTimelapses:
                    title = "Time Lapses"
                    break
                case .smartAlbumUserLibrary:
                    continue
                default:
                    title = collection.localizedTitle
                    break
                }
                
                self.albums.append(AlbumItem(title: title, image: self.getLastThumbnail(collection), collection: collection))
            }
        }
    }
    
    @objc func cancelAction() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func getLastThumbnail(_ collection: PHAssetCollection?) -> UIImage? {
        var thumbnail: UIImage? = nil
        
        if let lastAsset = fetchVideos(collection!).lastObject as? PHAsset {
            
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
            imageRequestOptions.isSynchronous = true
            
            let targetWidthHeight = 64 * UIScreen.main.scale
            
            PHImageManager.default().requestImage(for: lastAsset, targetSize: CGSize(width: targetWidthHeight, height: targetWidthHeight), contentMode: PHImageContentMode.aspectFill, options: imageRequestOptions, resultHandler: { (image: UIImage?, info: [AnyHashable: Any]?) -> Void in
                thumbnail = image
            })
        }
        
        return thumbnail
    }
    
    func fetchVideos(_ collection: PHAssetCollection) -> PHFetchResult<AnyObject> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.video.rawValue)
        
        return PHAsset.fetchAssets(in: collection, options: fetchOptions) as! PHFetchResult<AnyObject>
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension SelectAlbumController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        loadData()
    }
}
