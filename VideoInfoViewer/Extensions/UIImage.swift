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

import Foundation

extension UIImage {

    func toSquare() -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: self.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat
        var posY: CGFloat
        var cgwidth: CGFloat
        var cgheight: CGFloat
        
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        let image: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        return image
    }
    
    func rotate(_ degrees: CGFloat) -> UIImage {
        
        let rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        rotatedViewBox.transform = CGAffineTransform(rotationAngle: degrees * CGFloat(Double.pi / 180))
        
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        UIGraphicsBeginImageContext(rotatedSize)
        
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: (degrees * CGFloat(Double.pi / 180)))
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
