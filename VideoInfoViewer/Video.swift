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

import CoreData
import Foundation

public struct Video {
    
    var coreDataObject: NSManagedObject!
    
    var assetId: String!
    var videoURL: NSURL!
    var thumbURL: NSURL!
    var openDate: NSDate!
    var creationDate: NSDate!
    
    init(fromObject object: NSManagedObject) {
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