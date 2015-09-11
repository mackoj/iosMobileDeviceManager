//
//  ViewController.swift
//  MDM
//
//  Created by Jeffrey Macko on 08/09/15.
//  Copyright (c) 2015 PagesJaunes. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {
  
  @IBOutlet weak var deveiceStateSwitch: UISwitch!
  @IBOutlet weak var loginTextField: UITextField!
  
  override func viewWillAppear(animated: Bool) {
    self.loginTextField.becomeFirstResponder()
  }
  
  func validateForm() {

    let userLogin = loginTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    let userMail = "\(userLogin)@pagesjaunes.fr"
    
    let isUserExist =  PFQuery(className: "PJUser", predicate: NSPredicate(format: "login == %@", userLogin))
    isUserExist.getFirstObjectInBackgroundWithBlock {
      (userRetreive, error) -> Void in
      if (error != nil)
      {
        NSLog("%@", error!)
        let user = PFObject(className: "PJUser")
        user.setObject(userLogin, forKey: "login")
        user.setObject(userMail, forKey: "mail")
        user.saveInBackgroundWithBlock {
          (success, error) -> Void in
          if success {
            NSLog("PJUser object created with id: \(user.objectId)")
            self.updateBorrowedDeviceInfo(user)
          } else {
            NSLog("%@", error!)
          }
        }
      }
      else
      {
        if let tmpUser = userRetreive {
          NSLog("PJUser retrieved with id: \(tmpUser.objectId)")
          self.updateBorrowedDeviceInfo(tmpUser)
        }
        else
        {
          NSLog("PJUser Object is invalid")
          UIAlertView(title: "", message: "Veuillez contacter un dev iOS.\n0x22", delegate: nil, cancelButtonTitle: "Fermer").show()
        }
      }
    }
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    self.validateForm()
    return true
  }
  
  @IBAction func saveUserName(sender: UITextField) {
    self.validateForm()
  }
  
  func updateBorrowedDeviceInfo(user: PFObject) {
    
    let modelName = UIDevice.currentDevice().modelName
    let model = UIDevice.currentDevice().model
    let manufacturer = "Apple"
    let systemName = UIDevice.currentDevice().systemName
    let systemVersion = UIDevice.currentDevice().systemVersion
    let dateMinus5Minutes = NSDate(timeInterval: -60*5, sinceDate: NSDate());
    
    let isRecentlyBorrowedByMe =  PFQuery(className: "BorrowedDevice", predicate: NSPredicate(format: "userId == %@ AND updatedAt > %@ AND instalationId == %@", user, dateMinus5Minutes, PFInstallation.currentInstallation()))
    isRecentlyBorrowedByMe.getFirstObjectInBackgroundWithBlock {
      (borrowedDeviceRetreive, error) -> Void in
      if (error != nil)
      {
        NSLog("%@", error!)
        let borrowedDevice = PFObject(className: "BorrowedDevice")
        borrowedDevice.setObject(modelName, forKey: "model")
        borrowedDevice.setObject(model, forKey: "type")
        borrowedDevice.setObject(user, forKey: "userId")
        borrowedDevice.setObject(PFInstallation.currentInstallation(), forKey: "instalationId")
        borrowedDevice.setObject(manufacturer, forKey: "manufacturer")
        borrowedDevice.setObject(self.deveiceStateSwitch.on, forKey: "broken")
        borrowedDevice.setObject(systemName, forKey: "systemName")
        borrowedDevice.setObject(systemVersion, forKey: "systemVersion")
        borrowedDevice.saveInBackgroundWithBlock {
          (success, error) -> Void in
          if success {
            NSLog("BorrowedDevice object created with id: \(borrowedDevice.objectId)")
            UIAlertView(title: "", message: "Enregistré", delegate: nil, cancelButtonTitle: "Fermer").show()
            
          } else {
            NSLog("%@", error!)
          }
        }
      }
      else
      {
        if let tmpBorrowedDeviceRetreive = borrowedDeviceRetreive {
          NSLog("BorrowedDevice retrieved with id: \(tmpBorrowedDeviceRetreive.objectId)")
          UIAlertView(title: "", message: "Votre sessions n'a pas été enregistrer car elle date de moins de 5 minutes", delegate: nil, cancelButtonTitle: "Fermer").show()
        }
        else
        {
          NSLog("BorrowedDevice Object is invalid")
          UIAlertView(title: "", message: "Veuillez contacter un dev iOS.\n0x23", delegate: nil, cancelButtonTitle: "Fermer").show()
        }
      }
    }
    
  }
  
}

public extension UIDevice {
  
  var modelName: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    
    let machine = systemInfo.machine
    let mirror = Mirror(reflecting: machine)
    var identifier = ""
    
    for child in mirror.children where child.value as? Int8 != 0 {
      identifier.append(UnicodeScalar(UInt8(child.value as! Int8)))
    }
    
    return identifier
  }
  
}
