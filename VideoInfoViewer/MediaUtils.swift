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
import Foundation
import UIKit

class MediaUtils {
    
    static func renderThumbnailFromVideo(videoURL: NSURL, thumbnailURL: NSURL, time: CMTime) -> Bool {
        let asset = AVURLAsset(URL: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let cgImage = try imgGenerator.copyCGImageAtTime(time, actualTime: nil)
            let uiImage = UIImage(CGImage: cgImage)
            
            let result = UIImagePNGRepresentation(uiImage)?.writeToURL(thumbnailURL, atomically: true)
            return result != nil
        } catch _ {
            print("Failed to get thumbnail")
        }
        return false
    }
    
    static func getVideoDuration(videoURL: NSURL) -> CMTime{
        let asset = AVURLAsset(URL: videoURL, options: nil)
        return asset.duration
    }
}