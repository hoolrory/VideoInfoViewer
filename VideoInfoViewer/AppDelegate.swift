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
    var dispatchHandler: ((_ result:GAIDispatchResult) -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if let gaFile = Bundle.main.url(forResource: "googleAnalytics", withExtension: "txt") {
            do {
                let trackingId = try NSString(contentsOf: gaFile, encoding: String.Encoding.utf8.rawValue)
                    
                if trackingId.length > 0 {
                    
                    let gai = GAI.sharedInstance()
                    gai?.trackUncaughtExceptions = true
                    gai?.logger.logLevel = GAILogLevel.none
                    _ = gai?.tracker(withTrackingId: trackingId as String)
                }
            } catch _ {
                print("Failed to setup Google Analytics")
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        self.sendHitsInBackground()
        completionHandler(.newData)
    }
    
    func sendHitsInBackground() {
        self.okToWait = true
        weak var weakSelf = self
        
        let backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            weakSelf?.okToWait = false
        })
        
        if backgroundTaskId == UIBackgroundTaskIdentifier.invalid {
            return
        }
        
        self.dispatchHandler = { (result) -> Void in
            
            if let weakSelf = weakSelf {
                if result == .good && weakSelf.okToWait {
                    GAI.sharedInstance().dispatch(completionHandler: weakSelf.dispatchHandler)
                } else {
                    UIApplication.shared.endBackgroundTask(backgroundTaskId)
                }
            }
        }
        
        GAI.sharedInstance().dispatch(completionHandler: self.dispatchHandler)
    
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        self.sendHitsInBackground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        if let vc = self.window?.rootViewController as? UINavigationController {
            vc.popToRootViewController(animated: false)
            if let main = vc.visibleViewController as? MainViewController {
                main.handleURL(url)
            }
        }
        return true
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "VideoInfoViewer", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch let error as NSError {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
