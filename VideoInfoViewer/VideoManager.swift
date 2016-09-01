//
//  VideoManager.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 8/31/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import AVFoundation
import CoreData
import Foundation
import Photos

class VideoManager {
    
    lazy var managedContext: NSManagedObjectContext? = {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            return appDelegate.managedObjectContext
        }
        
        return nil
    }()
    
    func getVideos() -> [Video] {
        var videos = [Video]()
        
        let fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "openDate", ascending: false)]
            
        do {
            let results = try managedContext?.executeFetchRequest(fetchRequest)
            if let objects = results as? [NSManagedObject] {
                for object in objects {
                    videos.append(Video(fromObject: object))
                }
            }
        } catch _ {
        
        }
        
        return videos
    }
    
    func getVideoByAssetId(assetId: String) -> Video? {
        let fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
        
        do {
            let results = try managedContext?.executeFetchRequest(fetchRequest)
            if let objects = results as? [NSManagedObject] {
                if objects.count == 1 {
                    return Video(fromObject: objects[0])
                }
            }
        } catch _ {
            
        }
        
        return nil
    }
    
    func updateOpenDate(video: Video) {
        video.coreDataObject.setValue(NSDate(), forKey: "openDate")
            
        do {
            try managedContext?.save()
        } catch _ {
            
        }
    }
    
    func addVideoFromAVURLAsset(asset: AVURLAsset, phAsset: PHAsset) -> Video? {
        let filemgr = NSFileManager.defaultManager()
        let lastPathComponent = asset.URL.lastPathComponent
        let videoName = lastPathComponent != nil ? lastPathComponent! :"video_\(NSDate().timeIntervalSince1970).MOV"
        
        let videoURL = getDocumentUrl(videoName)
        let creationDate = phAsset.creationDate
        let assetId = phAsset.localIdentifier
        
        do {
            try filemgr.copyItemAtURL(asset.URL, toURL: videoURL)
        } catch _ {
            print("Failed to copy")
            return nil
        }
        
        let thumbnailURL = getDocumentUrl("\(videoName).png")
        let duration = MediaUtils.getVideoDuration(videoURL)
        let thumbTime = CMTime(seconds: duration.seconds / 2.0, preferredTimescale: duration.timescale)
        
        MediaUtils.renderThumbnailFromVideo(videoURL, thumbnailURL: thumbnailURL, time: thumbTime)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let entity =  NSEntityDescription.entityForName("Video", inManagedObjectContext:managedContext)
        
        let object = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        object.setValue(assetId, forKey: "assetId")
        object.setValue(videoURL.lastPathComponent, forKey: "videoFile")
        object.setValue(thumbnailURL.lastPathComponent, forKey: "thumbFile")
        object.setValue(NSDate(), forKey: "openDate")
        object.setValue(creationDate, forKey: "creationDate")
        
        do {
            try managedContext.save()
            
            return Video(fromObject: object)
        } catch let error  {
            print("Could not save \(error))")
        }

        
        return nil
    }
    
    func getDocumentUrl(pathComponent : String) -> NSURL {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        guard let documentDirectory: NSURL = urls.first else {
            fatalError("documentDir Error")
        }
        
        return documentDirectory.URLByAppendingPathComponent(pathComponent)
    }
}