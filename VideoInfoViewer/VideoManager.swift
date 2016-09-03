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
    
    typealias CompletionHandler = (result:Video?) -> Void
    
    func addVideoFromAVURLAsset(asset: AVURLAsset, phAsset: PHAsset, completionHandler: CompletionHandler) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let filemgr = NSFileManager.defaultManager()
            let lastPathComponent = asset.URL.lastPathComponent
            let videoName = lastPathComponent != nil ? lastPathComponent! :"video_\(NSDate().timeIntervalSince1970).MOV"
            
            let videoURL = self.getDocumentUrl(videoName)
            let creationDate = phAsset.creationDate
            let assetId = phAsset.localIdentifier
            
            do {
                try filemgr.copyItemAtURL(asset.URL, toURL: videoURL)
            } catch _ {
                print("Failed to copy")
                completionHandler(result: nil)
            }
            
            let thumbURL = self.getDocumentUrl("\(videoName).png")
            
            let thumbSize: CGSize = CGSizeMake(CGFloat(phAsset.pixelWidth), CGFloat(phAsset.pixelHeight))
            
            let options = PHImageRequestOptions()
            options.synchronous = true
            
            let cachingImageManager = PHCachingImageManager()
            cachingImageManager.requestImageForAsset(phAsset, targetSize: thumbSize, contentMode: PHImageContentMode.AspectFill, options: options, resultHandler: { (image: UIImage?, info :[NSObject : AnyObject]?) -> Void in
                if let image = image {
                    UIImagePNGRepresentation(image)?.writeToURL(thumbURL, atomically: true)
                }
            })
            
            let video = self.addVideo(assetId, videoURL: videoURL, thumbURL: thumbURL, creationDate: creationDate)
            completionHandler(result: video)
        }
    }
    
    func addVideoFromURL(url: NSURL, completionHandler: CompletionHandler) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let filemgr = NSFileManager.defaultManager()
            let lastPathComponent = url.lastPathComponent
            let videoName = lastPathComponent != nil ? lastPathComponent! :"video_\(NSDate().timeIntervalSince1970).MOV"
            
            let videoURL = self.getDocumentUrl(videoName)
            let creationDate = NSDate()
            let assetId = ""
            
            do {
                try filemgr.copyItemAtURL(url, toURL: videoURL)
            } catch _ {
                print("Failed to copy")
                completionHandler(result: nil)
            }
            
            let thumbURL = self.getDocumentUrl("\(videoName).png")
            
            let duration = MediaUtils.getVideoDuration(videoURL)
            let thumbTime = CMTime(seconds: duration.seconds / 2.0, preferredTimescale: duration.timescale)
            
            MediaUtils.renderThumbnailFromVideo(videoURL, thumbURL: thumbURL, time: thumbTime)
            
            let video = self.addVideo(assetId, videoURL: videoURL, thumbURL: thumbURL, creationDate: creationDate)
            completionHandler(result: video)
        }
    }
    
    func addVideo(assetId: String, videoURL: NSURL, thumbURL: NSURL, creationDate: NSDate?) -> Video? {
        guard let managedContext = managedContext else { return nil }
        
        let entity =  NSEntityDescription.entityForName("Video", inManagedObjectContext:managedContext)
        
        let object = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        object.setValue(assetId, forKey: "assetId")
        object.setValue(videoURL.lastPathComponent, forKey: "videoFile")
        object.setValue(thumbURL.lastPathComponent, forKey: "thumbFile")
        object.setValue(NSDate(), forKey: "openDate")
        object.setValue(creationDate, forKey: "creationDate")
        
        do {
            try managedContext.save()
            
            removeOldVideos()
            
            return Video(fromObject: object)
        } catch let error  {
            print("Could not save \(error))")
        }
        
        
        return nil
    }
    
    func removeOldVideos() {
        let videos = getVideos()
        if videos.count > 5 {
            let videosToDelete = videos[5..<videos.count ]
            for video in videosToDelete {
                managedContext?.deleteObject(video.coreDataObject)
            }
            do {
                try managedContext?.save()
                
                let filemgr = NSFileManager.defaultManager()
                for video in videosToDelete {
                    
                    if let videoPath = video.videoURL.path {
                        if filemgr.fileExistsAtPath(videoPath) {
                            try filemgr.removeItemAtURL(video.videoURL)
                        }
                    }
                    if let thumbPath = video.thumbURL.path {
                        if filemgr.fileExistsAtPath(thumbPath) {
                            try filemgr.removeItemAtURL(video.thumbURL)
                        }
                    }
                }
            } catch let error  {
                print("Could not save \(error))")
            }
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
}