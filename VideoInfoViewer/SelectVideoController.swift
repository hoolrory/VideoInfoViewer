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
    
    private var assetGridThumbnailSize: CGSize = CGSizeMake(0, 0)
    
    let cellSpacing:CGFloat = 2
    let cachingImageManager = PHCachingImageManager()
    var collection: PHAssetCollection?
    var didSelectAsset: ((PHAsset!) -> ())?
    
    private var assets: [PHAsset]! {
        willSet {
            cachingImageManager.stopCachingImagesForAllAssets()
        }
        
        didSet {
            cachingImageManager.startCachingImagesForAssets(self.assets, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.AspectFill, options: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = UICollectionViewScrollDirection.Vertical
        
        collectionView?.collectionViewLayout = flowLayout
        collectionView?.backgroundColor = UIColor.whiteColor()
        collectionView?.registerClass(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "VideoCell")
        
        let scale = UIScreen.mainScreen().scale
        let cellSize = flowLayout.itemSize
        assetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale)
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Video.rawValue)
        
        let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(collection!, options: fetchOptions)
        assets = assetsFetchResult.objectsAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, assetsFetchResult.count))) as! [PHAsset]
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "SelectVideoController")
            let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
            tracker.send(builder as! [NSObject : AnyObject])
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("videoCell", forIndexPath: indexPath)
        cell.contentView.frame = cell.bounds
        cell.backgroundColor = UIColor.blackColor()
        
        let currentTag = cell.tag + 1
        cell.tag = currentTag
        
        var thumbnail: UIImageView!
        
        if cell.contentView.subviews.count == 0 {
            thumbnail = UIImageView(frame: cell.contentView.frame)
            thumbnail.contentMode = .ScaleAspectFill
            thumbnail.frame = cell.contentView.frame
            cell.contentView.addSubview(thumbnail)
        }
        else {
            thumbnail = cell.contentView.subviews[0] as! UIImageView
        }
        
        let asset = assets[indexPath.row]
        
        cachingImageManager.requestImageForAsset(asset, targetSize: assetGridThumbnailSize, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image: UIImage?, info: [NSObject : AnyObject]?) -> Void in
            if cell.tag == currentTag {
                thumbnail.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        navigationController?.popToRootViewControllerAnimated(true)
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.send(GAIDictionaryBuilder.createEventWithCategory("Video Info", action: "Selected video from album", label: "", value: 0).build() as [NSObject : AnyObject])
        }
        if didSelectAsset != nil {
            didSelectAsset!(assets[indexPath.row])
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.contentView.alpha = 0.5
    }
    
    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.contentView.alpha = 1.0
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SelectVideoController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let videosPerRow: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 4 : 8
        let size = (self.view.frame.size.width - (videosPerRow + 2) * cellSpacing) / videosPerRow
        return CGSizeMake(size, size)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(cellSpacing, cellSpacing, cellSpacing, cellSpacing)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return cellSpacing
    }
}
