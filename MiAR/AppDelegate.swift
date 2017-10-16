//
//  AppDelegate.swift
//  MiAR
//
//  Created by Oscar Bonilla on 10/9/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    var notes: [Note] = []
    let notificationCenter = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
      
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        notificationCenter.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in }
        notificationCenter.removeAllPendingNotificationRequests()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if Auth.auth().currentUser != nil {
            // User is signed in.
            let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            window?.rootViewController = vc
        } else {
            // No user is signed in.
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            window?.rootViewController = vc
        }
        window?.makeKeyAndVisible()

        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        notificationCenter.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in }
        notificationCenter.removeAllPendingNotificationRequests()
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            // [END new_delegate]
            return self.application(application,
                                    open: url,
                                    // [START new_options]
                sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                annotation: [:])
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // [END old_delegate]
        return GIDSignIn.sharedInstance().handle(url,
                                             sourceApplication: sourceApplication,
                                             annotation: annotation)
    }
    
    // [START headless_google_auth]
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // [START_EXCLUDE]
        // guard let controller = GIDSignIn.sharedInstance().uiDelegate as? LoginViewController else { return }
        
        // [START google_credential]
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // [END google_credential]
        // [START_EXCLUDE]
        Auth.auth().signIn(with: credential) { (fbUser, error) in
            print("User signed in")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            self.window?.rootViewController = vc
        }
        // [END_EXCLUDE]
    }
    // [END headless_google_auth]
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
    }

    func handleEvent(forRegion region: CLRegion!) {
        // Show an alert if application is active
        if UIApplication.shared.applicationState == .active {
            guard let message = note(fromRegionIdentifier: region.identifier) else { return }
            window?.rootViewController?.showAlert(withTitle: nil, message: message)
        } else {
            // Otherwise present a local notification
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey: "Incoming Message", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: "You have a new message!", arguments: nil)
            content.sound = UNNotificationSound.default()
            content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber;
//            content.categoryIdentifier = "com.elonchan.localNotification"
            // Deliver the notification in five seconds.
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5.0, repeats: false)
            let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
            
            // Schedule the notification.
            notificationCenter.add(request, withCompletionHandler: { (error) in
                if error != nil {
                    print("error: \(String(describing: error?.localizedDescription))")
                }
            })
        }
    }
    
    func note(fromRegionIdentifier identifier: String) -> String? {
        return "You have a new note!"
    }
    
    func monitorNotes() {
        for note in notes {
            startMonitoring(note: note)
        }
    }
    
    func add(note: Note) {
        notes.append(note)
    }
    
    func remove(note: Note) {
        if let indexInArray = notes.index(of: note) {
            notes.remove(at: indexInArray)
        }
    }
    
    func region(withNote note: Note) -> CLCircularRegion {
        let region = CLCircularRegion(center: note.coordinate, radius: note.radius, identifier: note.identifier)
        region.notifyOnEntry = (note.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func startMonitoring(note: Note) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
//            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            return
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
//            showAlert(withTitle:"Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        
        let region = self.region(withNote: note)
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(note: Note) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == note.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
}
