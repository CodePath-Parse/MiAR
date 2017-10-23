//
//  NewNoteViewController.swift
//  MiAR
//
//  Created by Oscar Bonilla on 10/12/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit
import CoreLocation

class NewNoteViewController: UIViewController {

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var drawView: UIView!
    
    var lastPoint = CGPoint.zero
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var swiped = false
    var noteImage: UIImage!
    let locationManager = CLLocationManager()
    var activeTextView: UITextView!
    var emptyNote = true
    var dismissingKeyboard = false
    var note: Note?
    
    var completion: ((Note) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        noteTextView.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewNoteViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        registerForKeyboardNotifications()
    }
    
    // MARK: - Drawing functions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches began")
        if dismissingKeyboard {
            return
        }
        
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: mainImageView)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches moved")
        if dismissingKeyboard {
            return
        }
        
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: mainImageView)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches ended")
        if dismissingKeyboard {
            dismissingKeyboard = false
            return
        }
        
        if !swiped {
            // draw a single point
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
        }
        
//        backgroundImageView.image = UIImage(named: "background")
//        let rect = AVMakeRect(aspectRatio: backgroundImageView.image?.size ?? view.frame.size, insideRect: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(mainImageView.frame.size)
//        backgroundImageView.image?.draw(in: rect, blendMode: .normal, alpha: 1.0)
        
        mainImageView.image?.draw(in: CGRect(x: 0, y: 0, width: mainImageView.frame.size.width, height: mainImageView.frame.size.height), blendMode: .normal, alpha: 1.0)
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: mainImageView.frame.size.width, height: mainImageView.frame.size.height), blendMode: .normal, alpha: opacity)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContext(mainImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        if let context = context {
            tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: mainImageView.frame.size.width, height: mainImageView.frame.size.height))
            
            context.move(to: fromPoint)
            context.addLine(to: toPoint)
            context.setLineCap(.round)
            context.setLineWidth(brushWidth)
            context.setStrokeColor(red: red, green: green, blue: blue, alpha: 1.0)
            context.setBlendMode(.normal)
            context.strokePath()
            
            tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            tempImageView.alpha = opacity
        }
        UIGraphicsEndImageContext()
    }
    
    // MARK: - Button actions
    let colors: [(CGFloat, CGFloat, CGFloat)] = [
        (0, 0, 0),
        (105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0),
        (1.0, 0, 0),
        (0, 0, 1.0),
        (51.0 / 255.0, 204.0 / 255.0, 1.0),
        (102.0 / 255.0, 1.0, 0),
        (160.0 / 255.0, 82.0 / 255.0, 45.0 / 255.0),
        (1.0, 102.0 / 255.0, 0),
        (1.0, 1.0, 0),
        (1.0, 1.0, 1.0),
        ]
    @IBAction func colorPicked(_ sender: AnyObject) {
        print("color picked")
        var index = sender.tag ?? 0
        if index < 0 || index >= colors.count {
            index = 0
        }
        
        (red, green, blue) = colors[index]
        if index == colors.count - 1 {
            opacity = 1.0
        }
    }
    
    @IBAction func reset(_ sender: Any) {
        mainImageView.image = nil
    }
    
    @IBAction func eraser(_ sender: Any) {
        (red, green, blue) = colors[colors.count - 1]
        opacity = 1.0
    }
    
    @IBAction func onCancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }
    
    @IBAction func onSendButton(_ sender: Any) {
        UIGraphicsBeginImageContext(mainImageView.bounds.size)
        mainImageView.image?.draw(in: CGRect(x: 0, y: 0,
                                               width: mainImageView.frame.size.width, height: mainImageView.frame.size.height))
        noteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        var currentLocation: CLLocation? = nil
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locationManager.location
        }
        
        // we can call to create the note here or pass along to another VC to ask for sharing options
        let note = Note(to: User.currentUser!, text: noteTextView.text, image: noteImage, location: currentLocation?.coordinate)
        completion?(note)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Keyboard and scrolling
    @objc func dismissKeyboard() {
        print("dismiss keyboard")
        view.endEditing(true)
    }
    
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
        print("keyboard shown")
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        dismissingKeyboard = true
        
        var aRect = view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeView = activeTextView.superview {
            let viewPoint = CGPoint(x: activeView.frame.origin.x, y: activeView.frame.origin.y + activeView.frame.size.height)
            if (!aRect.contains(viewPoint)){
                let translateY = aRect.size.height - (viewPoint.y + activeView.frame.size.height)
                drawView.transform = CGAffineTransform(translationX: 0, y: translateY)
            }
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification){
        print("keyboard hidden")
        drawView.transform = CGAffineTransform.identity
    }
    
    deinit {
        deregisterFromKeyboardNotifications()
    }
}

// MARK: - TextView delegate
extension NewNoteViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        activeTextView = textView
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("text view begin editing")
        if emptyNote {
            textView.text = ""
            emptyNote = false
        }
        
        textView.textColor = UIColor.black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("text view end editing")
        if textView.text.isEmpty {
            emptyNote = true
            noteTextView.text = "#Leave a message"
            noteTextView.textColor = UIColor.lightGray
        }
        
        activeTextView = nil
    }
}

