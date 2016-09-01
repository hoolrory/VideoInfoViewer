//
//  Video.swift
//  VideoInfoViewer
//
//  Created by Hool, Rory on 8/25/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

import Foundation

public struct Video {
    
    var coreDataObject: NSObject!
    
    var assetId: String!
    var videoURL: NSURL!
    var thumbURL: NSURL!
    var openDate: NSDate!
    var creationDate: NSDate!
    
    init(fromObject object: NSObject) {
        coreDataObject = object
        
        if let videoFile = object.valueForKey("videoFile") as? String {
            videoURL = getDocumentUrl(videoFile)
        }
        if let thumbFile = object.valueForKey("thumbFile") as? String {
            thumbURL = getDocumentUrl(thumbFile)
        }
        
        assetId = object.valueForKey("assetId") as? String
        openDate = object.valueForKey("openDate") as? NSDate
        creationDate = object.valueForKey("creationDate") as? NSDate
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