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
        let rotation = getVideoRotation(videoURL)
        do {
            let cgImage = try imgGenerator.copyCGImageAtTime(time, actualTime: nil)
            var uiImage = UIImage(CGImage: cgImage)
            
            if rotation != 0 {
                uiImage = rotateImageByDegrees(uiImage, degrees: CGFloat(rotation))
            }
            
            let result = UIImagePNGRepresentation(uiImage)?.writeToURL(thumbnailURL, atomically: true)
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
    
    static func getVideoRotation(videoURL: NSURL) -> Float {
        let asset = AVURLAsset(URL: videoURL, options: nil)
        
        let videoTracks = asset.tracksWithMediaType(AVMediaTypeVideo)
        
        if videoTracks.count == 0 {
            return 0.0
        }
        
        let transform = videoTracks[0].preferredTransform
    
        let radians = atan2f(Float(transform.b), Float(transform.a))
        let videoAngleInDegrees = (radians * 180.0) / Float(M_PI)
        
        return videoAngleInDegrees
    }
    
    static func rotateImageByDegrees(oldImage: UIImage, degrees: CGFloat) -> UIImage {
        let rotatedViewBox = UIView(frame: CGRectMake(0, 0, oldImage.size.width, oldImage.size.height))
        let transform = CGAffineTransformMakeRotation(degrees * CGFloat(M_PI / 180))
        rotatedViewBox.transform = transform
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        UIGraphicsBeginImageContext(rotatedSize)
        let context = UIGraphicsGetCurrentContext()!
        CGContextTranslateCTM(context, rotatedSize.width / 2, rotatedSize.height / 2)
        CGContextRotateCTM(context, (degrees * CGFloat(M_PI / 180)))
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextDrawImage(context, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), oldImage.CGImage)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}