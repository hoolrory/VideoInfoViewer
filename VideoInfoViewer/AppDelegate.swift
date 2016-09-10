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
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var okToWait = false
    var dispatchHandler: ((result:GAIDispatchResult) -> Void)?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if let gaFile = NSBundle.mainBundle().URLForResource("googleAnalytics", withExtension: "txt") {
            do {
                let trackingId = try NSString(contentsOfURL: gaFile, encoding: NSUTF8StringEncoding)
                    
                if trackingId.length > 0 {
                    
                    let gai = GAI.sharedInstance()
                    gai.trackUncaughtExceptions = true
                    gai.logger.logLevel = GAILogLevel.None
                    gai.trackerWithTrackingId(trackingId as String)
                }
            } catch _ {
                print("Failed to setup Google Analytics")
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        self.sendHitsInBackground()
        completionHandler(.NewData)
    }
    
    func sendHitsInBackground() {
        self.okToWait = true
        weak var weakSelf = self
        
        let backgroundTaskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            weakSelf?.okToWait = false
        })
        
        if backgroundTaskId == UIBackgroundTaskInvalid {
            return
        }
        
        self.dispatchHandler = { (result) -> Void in
            
            if let weakSelf = weakSelf {
                if result == .Good && weakSelf.okToWait {
                    GAI.sharedInstance().dispatchWithCompletionHandler(weakSelf.dispatchHandler)
                } else {
                    UIApplication.sharedApplication().endBackgroundTask(backgroundTaskId)
                }
            }
        }
        
        GAI.sharedInstance().dispatchWithCompletionHandler(self.dispatchHandler)
    
    }

    func applicationDidEnterBackground(application: UIApplication) {
        self.sendHitsInBackground()
    }

    func applicationWillTerminate(application: UIApplication) {
        self.saveContext()
    }
    
    func application(app: UIApplication, openURL url: NSURL,
                     options: [String : AnyObject]) -> Bool {
        if let vc = self.window?.rootViewController as? UINavigationController {
            vc.popToRootViewControllerAnimated(false)
            if let main = vc.visibleViewController as? MainViewController {
                main.handleURL(url)
            }
        }
        return true
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("VideoInfoViewer", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch let error as NSError {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error
            let wrappedError = NSError(domain: "com.rory.p.hool.VideoInfoViewer", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        } catch {
            // dummy via http://stackoverflow.com/questions/34722649/errortype-is-not-convertible-to-nserror
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
