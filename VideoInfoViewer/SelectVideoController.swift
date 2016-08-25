//
//  SelectVideoController.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 8/23/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import UIKit
import Photos

class SelectVideoController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
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
            thumbnail.backgroundColor = UIColor.redColor()
            thumbnail.frame = cell.contentView.frame
            cell.contentView.addSubview(thumbnail)
        }
        else {
            thumbnail = cell.contentView.subviews[0] as! UIImageView
        }
        
        let asset = assets[indexPath.row]
        
        cachingImageManager.requestImageForAsset(asset, targetSize: assetGridThumbnailSize, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image: UIImage?, info :[NSObject : AnyObject]?) -> Void in
            if cell.tag == currentTag {
                thumbnail.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        navigationController?.popToRootViewControllerAnimated(true)
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