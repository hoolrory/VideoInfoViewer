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
    
    static func renderThumbnailFromVideo(_ videoURL: URL, thumbURL: URL, time: CMTime) -> Bool {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        let rotation = getVideoRotation(videoURL)
        do {
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
            var uiImage = UIImage(cgImage: cgImage)
            
            if rotation != 0 {
                uiImage = uiImage.rotate(CGFloat(rotation))
            }
            
            let result = try? uiImage.pngData()?.write(to: thumbURL, options: [.atomic])
            return result != nil
        } catch _ {
            print("Failed to get thumbnail")
        }
        return false
    }
    
    static func getVideoDuration(_ videoURL: URL) -> CMTime {
        let asset = AVURLAsset(url: videoURL, options: nil)
        return asset.duration
    }
    
    static func getVideoResolution(_ videoURL: URL) -> CGSize {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        
        if videoTracks.count == 0 {
            return CGSize(width: 0, height: 0)
        }
        
        return videoTracks[0].naturalSize

    }
    
    static func getVideoFrameRate(_ videoURL:URL) -> Float {
        let asset = AVURLAsset(url: videoURL, options: nil)
        
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        
        if videoTracks.count == 0 {
            return 0
        }
        
        return videoTracks[0].nominalFrameRate
    }
    
    static func getVideoMimeType(_ videoURL:URL) -> String {
        if videoURL.lastPathComponent.contains(".mov"){
            return "video/quicktime"
        } else {
            return "video/mp4"
        }
    }
    
    static func getVideoFileSize(_ videoURL: URL) -> String {
        var fileSize: UInt64 = 0
        
        do {
            let attr: NSDictionary? = try FileManager.default.attributesOfItem(atPath: videoURL.path) as NSDictionary?
            
            if let _attr = attr {
                fileSize = _attr.fileSize()
            }
        } catch {
            print("Error: \(error)")
        }
        
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    static func getVideoDurationFormatted(_ videoURL:URL) -> String {
        let totalSeconds = CMTimeGetSeconds(getVideoDuration(videoURL))
        let hours = floor(totalSeconds / 3600)
        let minutes = floor(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)
        
        if hours == 0 {
            return NSString(format:"%02.0f:%02.0f", minutes, seconds) as String
        } else {
            return NSString(format:"%02.0f:%02.0f:%02.0f", hours, minutes, seconds) as String
        }
    }
    
    static func getVideoBitrate(_ videoURL: URL) -> String {
        let asset = AVURLAsset(url: videoURL)
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        
        if videoTracks.count == 0 {
            return ""
        }
        
        return String(format:"%.0f kbps", videoTracks[0].estimatedDataRate/1024)
    }
    
    static func getVideoRotation(_ videoURL: URL) -> Float {
        let asset = AVURLAsset(url: videoURL)
        
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        
        if videoTracks.count == 0 {
            return 0.0
        }
        
        let transform = videoTracks[0].preferredTransform
    
        let radians = atan2f(Float(transform.b), Float(transform.a))
        let videoAngleInDegrees = (radians * 180.0) / .pi
        
        return videoAngleInDegrees
    }
}
