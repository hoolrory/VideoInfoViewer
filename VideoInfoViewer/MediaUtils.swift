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
    
    static func renderThumbnailFromVideo(videoURL: NSURL, thumbURL: NSURL, time: CMTime) -> Bool {
        let asset = AVURLAsset(URL: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        let rotation = getVideoRotation(videoURL)
        do {
            let cgImage = try imgGenerator.copyCGImageAtTime(time, actualTime: nil)
            var uiImage = UIImage(CGImage: cgImage)
            
            if rotation != 0 {
                uiImage = uiImage.rotate(CGFloat(rotation))
            }
            
            let result = UIImagePNGRepresentation(uiImage)?.writeToURL(thumbURL, atomically: true)
            return result != nil
        } catch _ {
            print("Failed to get thumbnail")
        }
        return false
    }
    
    static func getVideoDuration(videoURL: NSURL) -> CMTime {
        let asset = AVURLAsset(URL: videoURL, options: nil)
        return asset.duration
    }
    
    static func getVideoResolution(videoURL: NSURL) -> CGSize {
        let asset = AVURLAsset(URL: videoURL, options: nil)
        let videoTracks = asset.tracksWithMediaType(AVMediaTypeVideo)
        
        if videoTracks.count == 0 {
            return CGSizeMake(0, 0)
        }
        
        return videoTracks[0].naturalSize

    }
    
    static func getVideoFrameRate(videoURL:NSURL) -> Float {
        let asset = AVURLAsset(URL: videoURL, options: nil)
        
        let videoTracks = asset.tracksWithMediaType(AVMediaTypeVideo)
        
        if videoTracks.count == 0 {
            return 0
        }
        
        return videoTracks[0].nominalFrameRate
    }
    
    static func getVideoMimeType(videoURL:NSURL) -> String {
        if videoURL.lastPathComponent!.containsString(".mov"){
            return "video/quicktime"
        } else {
            return "video/mp4"
        }
    }
    
    static func getVideoFileSize(videoURL: NSURL) -> String {
        var fileSize: UInt64 = 0
        
        do {
            let attr: NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(videoURL.path!)
            
            if let _attr = attr {
                fileSize = _attr.fileSize()
            }
        } catch {
            print("Error: \(error)")
        }
        
        let formatter = NSByteCountFormatter()
        return formatter.stringFromByteCount(Int64(fileSize))
    }
    
    static func getVideoDurationFormatted(videoURL:NSURL) -> String {
        let totalSeconds = CMTimeGetSeconds(getVideoDuration(videoURL))
        let hours = floor(totalSeconds / 3600)
        let minutes = floor(totalSeconds % 3600 / 60)
        let seconds = floor(totalSeconds % 3600 % 60)
        
        if hours == 0 {
            return NSString(format:"%02.0f:%02.0f", minutes, seconds) as String
        } else {
            return NSString(format:"%02.0f:%02.0f:%02.0f", hours, minutes, seconds) as String
        }
    }
    
    static func getVideoBitrate(videoURL: NSURL) -> String {
        let asset = AVURLAsset(URL: videoURL)
        let videoTracks = asset.tracksWithMediaType(AVMediaTypeVideo)
        
        if videoTracks.count == 0 {
            return ""
        }
        
        return String(format:"%.0f kbps", videoTracks[0].estimatedDataRate/1024)
    }
    
    static func getVideoRotation(videoURL: NSURL) -> Float {
        let asset = AVURLAsset(URL: videoURL)
        
        let videoTracks = asset.tracksWithMediaType(AVMediaTypeVideo)
        
        if videoTracks.count == 0 {
            return 0.0
        }
        
        let transform = videoTracks[0].preferredTransform
    
        let radians = atan2f(Float(transform.b), Float(transform.a))
        let videoAngleInDegrees = (radians * 180.0) / Float(M_PI)
        
        return videoAngleInDegrees
    }
}