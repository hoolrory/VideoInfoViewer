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

import UIKit
import MobileCoreServices
import CoreData

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    var videos = [NSManagedObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Video Info Viewer"
        
        
        let openButton = UIBarButtonItem()
        openButton.title = "Open"
        openButton.action = #selector(ViewController.clickOpen(_:))
        openButton.target = self
        
        self.navigationItem.rightBarButtonItem = openButton
        
        imagePicker.delegate = self
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Video")
        
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            videos = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    @IBAction func clickOpen(sender: UIBarButtonItem) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaUrl = info[UIImagePickerControllerMediaURL] as? NSURL// as String
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        if let srcURL = mediaUrl {
            print(srcURL)
            let filemgr = NSFileManager.defaultManager()
            
            var fileName = "video_\(NSDate().timeIntervalSince1970).MOV"
            if let lastPathCompontent = srcURL.lastPathComponent {
                fileName = lastPathCompontent
            }
        
            let toURL = getDocumentUrl(fileName)
        
            do {
                try filemgr.copyItemAtURL(srcURL, toURL: toURL)
            } catch _ {
                print("Failed to copy")
                return
            }
            
            saveVideo(toURL)
            print(videos.count)
        } else {
            print("Failed to unpack media url")
        }
    }

    func saveVideo(videoURL: NSURL) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        
        let entity =  NSEntityDescription.entityForName("Video", inManagedObjectContext:managedContext)
        
        let video = NSManagedObject(entity: entity!,
                                     insertIntoManagedObjectContext: managedContext)
        
        video.setValue(videoURL.absoluteString, forKey: "videoURL")
        
        do {
            try managedContext.save()
            videos.append(video)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

