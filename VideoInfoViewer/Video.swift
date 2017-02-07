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
    var videoURL: URL!
    var thumbURL: URL!
    var openDate: Date!
    var creationDate: Date!
    
    init(fromObject object: NSManagedObject) {
        coreDataObject = object
        
        if let videoFile = object.value(forKey: "videoFile") as? String {
            videoURL = getDocumentUrl(videoFile)
        }
        if let thumbFile = object.value(forKey: "thumbFile") as? String {
            thumbURL = getDocumentUrl(thumbFile)
        }
        
        assetId = object.value(forKey: "assetId") as? String
        openDate = object.value(forKey: "openDate") as? Date
        creationDate = object.value(forKey: "creationDate") as? Date
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
