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
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            return appDelegate.managedObjectContext
        }
        
        return nil
    }()
    
    
    let backgroundQueue = DispatchQueue(label: "backgroundQueue")
    
    func getVideos() -> [Video] {
        var videos = [Video]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "openDate", ascending: false)]
        
        do {
            let results = try managedContext?.fetch(fetchRequest)
            if let objects = results as? [NSManagedObject] {
                for object in objects {
                    videos.append(Video(fromObject: object))
                }
            }
        } catch _ {
            
        }
        
        return videos
    }
    
    func getVideoByAssetId(_ assetId: String) -> Video? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
        
        do {
            let results = try managedContext?.fetch(fetchRequest)
            if let objects = results as? [NSManagedObject] {
                if objects.count == 1 {
                    return Video(fromObject: objects[0])
                }
            }
        } catch _ {
            
        }
        
        return nil
    }
    
    func updateOpenDate(_ video: Video) {
        video.coreDataObject.setValue(Date(), forKey: "openDate")
        
        do {
            try managedContext?.save()
        } catch _ {
            
        }
    }
    
    typealias CompletionHandler = (_ result:Video?) -> Void
    
    func addVideoFromAVURLAsset(_ asset: AVURLAsset, phAsset: PHAsset, completionHandler: @escaping CompletionHandler) {
        
        backgroundQueue.async {
            let videoName = asset.url.lastPathComponent
            
            let videoURL = self.getDocumentUrl(videoName)
            let creationDate = phAsset.creationDate
            let assetId = phAsset.localIdentifier
            
            do {
                try FileManager.default.copyItem(at: asset.url, to: videoURL)
            } catch _ {
                print("Failed to copy")
                completionHandler(nil)
            }
            
            let thumbURL = self.getDocumentUrl("\(videoName).png")
            
            let thumbSize: CGSize = CGSize(width: CGFloat(phAsset.pixelWidth), height: CGFloat(phAsset.pixelHeight))
            
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            
            let cachingImageManager = PHCachingImageManager()
            cachingImageManager.requestImage(for: phAsset, targetSize: thumbSize, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: { (image: UIImage?, info: [AnyHashable: Any]?) -> Void in
                if let image = image {
                    try? image.pngData()?.write(to: thumbURL, options: [.atomic])
                } else {
                    let duration = MediaUtils.getVideoDuration(videoURL)
                    let thumbTime = CMTime(seconds: duration.seconds / 2.0, preferredTimescale: duration.timescale)
                    
                    _ = MediaUtils.renderThumbnailFromVideo(videoURL, thumbURL: thumbURL, time: thumbTime)
                    
                }
            })
            
            let video = self.addVideo(assetId, videoURL: videoURL, thumbURL: thumbURL, creationDate: creationDate)
            completionHandler(video)
        }
    }
    
    func addVideoFromURL(_ url: URL, completionHandler: @escaping CompletionHandler) {
        
        backgroundQueue.async {
            let videoName = url.lastPathComponent
            
            let videoURL = self.getDocumentUrl(videoName)
            let creationDate = Date()
            let assetId = ""
            
            do {
                try FileManager.default.copyItem(at: url, to: videoURL)
            } catch _ {
                print("Failed to copy")
                completionHandler(nil)
            }
            
            let thumbURL = self.getDocumentUrl("\(videoName).png")
            
            let duration = MediaUtils.getVideoDuration(videoURL)
            let thumbTime = CMTime(seconds: duration.seconds / 2.0, preferredTimescale: duration.timescale)
            
            _ = MediaUtils.renderThumbnailFromVideo(videoURL, thumbURL: thumbURL, time: thumbTime)
            
            let video = self.addVideo(assetId, videoURL: videoURL, thumbURL: thumbURL, creationDate: creationDate)
            completionHandler(video)
        }
    }
    
    func addVideo(_ assetId: String, videoURL: URL, thumbURL: URL, creationDate: Date?) -> Video? {
        guard let managedContext = managedContext else { return nil }
        
        let entity =  NSEntityDescription.entity(forEntityName: "Video", in:managedContext)
        
        let object = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        object.setValue(assetId, forKey: "assetId")
        object.setValue(videoURL.lastPathComponent, forKey: "videoFile")
        object.setValue(thumbURL.lastPathComponent, forKey: "thumbFile")
        object.setValue(Date(), forKey: "openDate")
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
            let videosToDelete = videos[5 ..< videos.count ]
            for video in videosToDelete {
                removeVideo(video: video)
            }
        }
    }
    
    func removeVideo(video: Video) {
        managedContext?.delete(video.coreDataObject)
        
        do {
            try managedContext?.save()
            
            let filemgr = FileManager.default
            if filemgr.fileExists(atPath: video.videoURL.path) {
                try filemgr.removeItem(at: video.videoURL as URL)
            }
            if filemgr.fileExists(atPath: video.thumbURL.path) {
                try filemgr.removeItem(at: video.thumbURL as URL)
            }
        } catch let error  {
            print("Could not save \(error))")
        }
    }
    
    func getDocumentUrl(_ pathComponent: String) -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory: URL = urls.first else {
            fatalError("documentDir Error")
        }
        
        return documentDirectory.appendingPathComponent(pathComponent)
    }
}
