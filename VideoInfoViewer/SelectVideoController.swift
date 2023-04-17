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
import Photos

class SelectVideoController: UICollectionViewController {
    
    fileprivate var assetGridThumbnailSize: CGSize = CGSize(width: 0, height: 0)
    
    let cellSpacing:CGFloat = 2
    let cachingImageManager = PHCachingImageManager()
    var collection: PHAssetCollection?
    var didSelectAsset: ((PHAsset?) -> ())?
    
    fileprivate var assets: [PHAsset]! {
        willSet {
            cachingImageManager.stopCachingImagesForAllAssets()
        }
        
        didSet {
            cachingImageManager.startCachingImages(for: self.assets, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFill, options: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        
        collectionView?.collectionViewLayout = flowLayout
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "VideoCell")
        
        let scale = UIScreen.main.scale
        let cellSize = flowLayout.itemSize
        assetGridThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.video.rawValue)
        
        let assetsFetchResult = PHAsset.fetchAssets(in: collection!, options: fetchOptions)
        assets = assetsFetchResult.objects(at: IndexSet(integersIn: NSMakeRange(0, assetsFetchResult.count).toRange()!)) 
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "SelectVideoController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [AnyHashable: Any])
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath)
        cell.contentView.frame = cell.bounds
        cell.backgroundColor = UIColor.black
        
        let currentTag = cell.tag + 1
        cell.tag = currentTag
        
        var thumbnail: UIImageView!
        
        if cell.contentView.subviews.count == 0 {
            thumbnail = UIImageView(frame: cell.contentView.frame)
            thumbnail.contentMode = .scaleAspectFill
            thumbnail.frame = cell.contentView.frame
            cell.contentView.addSubview(thumbnail)
        }
        else {
            thumbnail = cell.contentView.subviews[0] as! UIImageView
        }
        
        let asset = assets[indexPath.row]
        
        cachingImageManager.requestImage(for: asset, targetSize: assetGridThumbnailSize, contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: { (image: UIImage?, info: [AnyHashable: Any]?) -> Void in
            if cell.tag == currentTag {
                thumbnail.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        _ = navigationController?.popToRootViewController(animated: true)
        if let tracker = GAI.sharedInstance().defaultTracker {
            let dictionary = GAIDictionaryBuilder.createEvent(withCategory: "Video Info", action: "Selected video from album", label: "", value: 0).build() as NSDictionary
            let event = dictionary as? [AnyHashable: Any] ?? [:]
            tracker.send(event)
        }
        if didSelectAsset != nil {
            didSelectAsset!(assets[indexPath.row])
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 0.5
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 1.0
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SelectVideoController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let videosPerRow: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 4 : 8
        let size = (self.view.frame.size.width - (videosPerRow + 2) * cellSpacing) / videosPerRow
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellSpacing, left: cellSpacing, bottom: cellSpacing, right: cellSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
}
